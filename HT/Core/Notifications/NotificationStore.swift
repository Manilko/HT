//
//  NotificationStore.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

@MainActor
class NotificationStore: ObservableObject {
  @Published var notifications: [ToastNotification] = []
  @Published var currentNotification: ToastNotification?

  private var dismissTasks: [UUID: Task<Void, Never>] = [:]

  func show(_ notification: ToastNotification) {
    currentNotification = notification

    dismissTasks[notification.id]?.cancel()

    dismissTasks[notification.id] = Task {
      try? await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000))

      if !Task.isCancelled {
        self.dismiss(notification.id)
      }
    }
  }

  func dismiss(_ id: UUID) {
    if currentNotification?.id == id {
      currentNotification = nil
    }

    dismissTasks[id]?.cancel()
    dismissTasks.removeValue(forKey: id)
  }

  func dismissAll() {
    for (id, task) in dismissTasks {
      task.cancel()
    }
    dismissTasks.removeAll()
    currentNotification = nil
  }
}
