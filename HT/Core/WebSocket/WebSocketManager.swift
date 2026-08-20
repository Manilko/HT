//
//  WebSocketManager.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Combine

@MainActor
class WebSocketManager: ObservableObject {
  static let shared = WebSocketManager()

  @Published var isConnected = false
  @Published var connectionError: Error?

  private let storageManager: StorageManager
  private var webSocketTask: URLSessionWebSocketTask?

  private init(storageManager: StorageManager = .shared) {
    self.storageManager = storageManager
  }

  func connect() async throws {
    guard let token = storageManager.accessToken else {
      throw WebSocketError.noAuthToken
    }

    let url = URL(string: "wss://api.habittracker.example/ws?token=\(token)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    webSocketTask = URLSession.shared.webSocketTask(with: request)
    webSocketTask?.resume()

    await MainActor.run {
      self.isConnected = true
    }

    receiveMessages()
  }

  func disconnect() async {
    webSocketTask?.cancel(with: .goingAway, reason: nil)
    webSocketTask = nil
    await MainActor.run {
      self.isConnected = false
    }
  }

  func send(message: WebSocketMessage) async throws {
    guard let webSocketTask = webSocketTask else {
      throw WebSocketError.notConnected
    }

    let encoder = JSONEncoder()
    let data = try encoder.encode(message)
    let jsonString = String(data: data, encoding: .utf8) ?? ""
    try await webSocketTask.send(.string(jsonString))
  }

  private func receiveMessages() {
    Task {
      while let webSocketTask = webSocketTask {
        do {
          let message = try await webSocketTask.receive()
          switch message {
          case .string(let text):
            handleMessage(text)
          case .data(let data):
            handleData(data)
          @unknown default:
            break
          }
        } catch {
          await MainActor.run {
            self.connectionError = error
            self.isConnected = false
          }
          break
        }
      }
    }
  }

  private func handleMessage(_ text: String) {
    // TODO: Parse and handle WebSocket messages
  }

  private func handleData(_ data: Data) {
    // TODO: Parse and handle WebSocket data
  }
}

struct WebSocketMessage: Codable {
  let type: String
  let data: [String: AnyCodable]?
  let timestamp: String?
}

enum WebSocketError: LocalizedError {
  case notConnected
  case noAuthToken
  case invalidMessage

  var errorDescription: String? {
    switch self {
    case .notConnected:
      return "WebSocket not connected"
    case .noAuthToken:
      return "No authentication token"
    case .invalidMessage:
      return "Invalid message"
    }
  }
}

enum AnyCodable: Codable {
  case null
  case bool(Bool)
  case int(Int)
  case double(Double)
  case string(String)
  case array([AnyCodable])
  case object([String: AnyCodable])

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .null:
      try container.encodeNil()
    case .bool(let value):
      try container.encode(value)
    case .int(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .string(let value):
      try container.encode(value)
    case .array(let value):
      try container.encode(value)
    case .object(let value):
      try container.encode(value)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(Int.self) {
      self = .int(value)
    } else if let value = try? container.decode(Double.self) {
      self = .double(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode([AnyCodable].self) {
      self = .array(value)
    } else if let value = try? container.decode([String: AnyCodable].self) {
      self = .object(value)
    } else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot decode AnyCodable"
      )
    }
  }
}
