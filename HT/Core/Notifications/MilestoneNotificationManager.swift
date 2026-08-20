//
//  MilestoneNotificationManager.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

@MainActor
class MilestoneNotificationManager: ObservableObject {
  private let webSocketService: WebSocketService
  private let notificationStore: NotificationStore
  private var eventTask: Task<Void, Never>?

  init(
    webSocketService: WebSocketService = WebSocketService(),
    notificationStore: NotificationStore = NotificationStore()
  ) {
    self.webSocketService = webSocketService
    self.notificationStore = notificationStore
  }

  func start() {
    stop()

    eventTask = Task {
      for await event in webSocketService.eventStream() {
        await handleWebSocketEvent(event)
      }
    }

    Task {
      await webSocketService.connect()
    }
  }

  func stop() {
    eventTask?.cancel()
    eventTask = nil

    Task {
      await webSocketService.disconnect()
    }
  }

  private func handleWebSocketEvent(_ event: WebSocketEvent) async {
    switch event {
    case .connected:
      print("✓ Connected to milestone notifications")

    case .disconnected:
      print("✗ Disconnected from milestone notifications")

    case .subscribed:
      print("✓ Subscribed to milestone notifications")

    case .milestone(let notification):
      let toast = ToastNotification.milestone(notification)
      notificationStore.show(toast)

    case .error(let message):
      let toast = ToastNotification(
        title: "Connection Error",
        message: message,
        type: .error,
        duration: 3.0
      )
      notificationStore.show(toast)

    case .reconnecting(let attempt):
      print("⟳ Reconnecting... (attempt \(attempt))")
    }
  }
}
