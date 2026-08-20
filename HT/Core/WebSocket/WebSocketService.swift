//
//  WebSocketService.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

@MainActor
class WebSocketService: NSObject, ObservableObject {
  @Published var isConnected = false
  @Published var connectionState: ConnectionState = .disconnected

  private let apiClient: APIClient
  private let storageManager: StorageManager
  private var webSocket: URLSessionWebSocketTask?
  private var receiveTask: Task<Void, Never>?
  private var reconnectTask: Task<Void, Never>?
  private var eventContinuation: AsyncStream<WebSocketEvent>.Continuation?
  private var eventStream: AsyncStream<WebSocketEvent>?

  private var reconnectAttempt = 0
  private let maxReconnectAttempts = 5
  private let reconnectDelay: TimeInterval = 3.0

  enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error(String)
    case reconnecting
  }

  init(
    apiClient: APIClient = .shared,
    storageManager: StorageManager = StorageManager.shared
  ) {
    self.apiClient = apiClient
    self.storageManager = storageManager
    super.init()
  }

  // MARK: - Public API

  func eventStream() -> AsyncStream<WebSocketEvent> {
    if let stream = eventStream {
      return stream
    }

    let stream = AsyncStream<WebSocketEvent> { continuation in
      self.eventContinuation = continuation
    }

    self.eventStream = stream
    return stream
  }

  func connect() async {
    guard !isConnected else { return }

    connectionState = .connecting
    await updateConnectionUI()

    do {
      guard let token = storageManager.getAccessToken() else {
        throw WebSocketError.missingToken
      }

      let wsUrl = buildWebSocketURL(token: token)

      let urlSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: .main
      )

      webSocket = urlSession.webSocketTask(with: wsUrl)
      webSocket?.resume()

      connectionState = .connected
      isConnected = true
      reconnectAttempt = 0

      await updateConnectionUI()
      emitEvent(.connected)

      await subscribe()
      await receiveMessages()
    } catch {
      connectionState = .error(error.localizedDescription)
      emitEvent(.error(error.localizedDescription))
      await updateConnectionUI()
      await scheduleReconnect()
    }
  }

  func disconnect() async {
    isConnected = false
    connectionState = .disconnected
    reconnectAttempt = 0

    receiveTask?.cancel()
    reconnectTask?.cancel()

    if let ws = webSocket {
      do {
        try await ws.send(.string(encodeMessage(ClientMessage.unsubscribe())))
      } catch {
        // Ignore error on disconnect
      }

      ws.cancel(with: .goingAway, reason: nil)
      webSocket = nil
    }

    await updateConnectionUI()
    emitEvent(.disconnected)
  }

  // MARK: - Private Methods

  private func subscribe() async {
    do {
      let message = ClientMessage.subscribe()
      let encoded = encodeMessage(message)
      try await webSocket?.send(.string(encoded))
      emitEvent(.subscribed)
    } catch {
      emitEvent(.error("Failed to subscribe: \(error.localizedDescription)"))
      await reconnect()
    }
  }

  private func receiveMessages() async {
    receiveTask = Task {
      while isConnected, let ws = webSocket {
        do {
          let message = try await ws.receive()

          switch message {
          case .string(let text):
            await handleMessage(text)

          case .data(let data):
            if let text = String(data: data, encoding: .utf8) {
              await handleMessage(text)
            }

          @unknown default:
            break
          }
        } catch {
          if isConnected {
            emitEvent(.error("Connection error: \(error.localizedDescription)"))
            await reconnect()
          }
          break
        }
      }
    }
  }

  private func handleMessage(_ text: String) async {
    do {
      let decoder = JSONDecoder()
      let serverMessage = try decoder.decode(ServerMessage.self, from: text.data(using: .utf8)!)

      switch serverMessage.type {
      case "streak_milestone":
        if let notification = try serverMessage.payload?.decode(as: MilestoneNotification.self) {
          emitEvent(.milestone(notification))
        }

      case "error":
        if let error = try serverMessage.payload?.decode(as: ErrorMessage.self) {
          emitEvent(.error(error.message))
        }

      default:
        emitEvent(.error("Unknown message type: \(serverMessage.type)"))
      }
    } catch {
      emitEvent(.error("Failed to parse message: \(error.localizedDescription)"))
    }
  }

  private func reconnect() async {
    guard reconnectAttempt < maxReconnectAttempts else {
      connectionState = .error("Max reconnection attempts reached")
      await updateConnectionUI()
      return
    }

    reconnectAttempt += 1
    connectionState = .reconnecting
    emitEvent(.reconnecting(attempt: reconnectAttempt))

    try? await Task.sleep(nanoseconds: UInt64(reconnectDelay * 1_000_000_000))

    webSocket?.cancel(with: .goingAway, reason: nil)
    webSocket = nil

    await connect()
  }

  private func scheduleReconnect() {
    reconnectTask = Task {
      try? await Task.sleep(nanoseconds: UInt64(reconnectDelay * 1_000_000_000))
      if !isConnected {
        await reconnect()
      }
    }
  }

  private func buildWebSocketURL(token: String) -> URL {
    guard let baseURL = URL(string: "ws://localhost:3000") else {
      fatalError("Invalid WebSocket URL")
    }

    var components = URLComponents(url: baseURL.appendingPathComponent("/api/ws"), resolvingAgainstBaseURL: true)!
    components.scheme = "ws"
    components.queryItems = [URLQueryItem(name: "token", value: token)]

    return components.url!
  }

  private func encodeMessage(_ message: ClientMessage) -> String {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(message),
       let json = String(data: data, encoding: .utf8) {
      return json
    }
    return "{}"
  }

  private func emitEvent(_ event: WebSocketEvent) {
    eventContinuation?.yield(event)
  }

  private func updateConnectionUI() {
    // Update published properties for UI binding
  }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketService: URLSessionWebSocketDelegate {
  nonisolated func urlSession(
    _: URLSession,
    webSocketTask _: URLSessionWebSocketTask,
    didOpenWithProtocol _: String?
  ) {
    // Connection opened
  }

  nonisolated func urlSession(
    _: URLSession,
    webSocketTask _: URLSessionWebSocketTask,
    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
    reason _: Data?
  ) {
    Task { @MainActor in
      if closeCode != .goingAway {
        await reconnect()
      }
    }
  }
}

// MARK: - Error Type

enum WebSocketError: LocalizedError {
  case missingToken
  case invalidURL
  case connectionFailed(String)
  case messageSendFailed(String)

  var errorDescription: String? {
    switch self {
    case .missingToken:
      return "Missing authentication token"
    case .invalidURL:
      return "Invalid WebSocket URL"
    case .connectionFailed(let reason):
      return "Connection failed: \(reason)"
    case .messageSendFailed(let reason):
      return "Message send failed: \(reason)"
    }
  }
}
