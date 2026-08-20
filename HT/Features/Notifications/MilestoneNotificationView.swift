//
//  MilestoneNotificationView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct MilestoneNotificationView: View {
  @StateObject private var wsService = WebSocketService()
  @State private var notification: MilestoneNotification?
  @State private var showNotification = false

  var body: some View {
    VStack(spacing: 16) {
      Text("Milestone Notifications")
        .font(.headline)

      if let notification = notification {
        notificationCard(notification)
      } else {
        Text("No notifications")
          .foregroundColor(.secondary)
      }
    }
    .padding()
    .task {
      for await event in wsService.eventStream() {
        handleEvent(event)
      }
    }
    .onAppear {
      Task {
        await wsService.connect()
      }
    }
    .onDisappear {
      Task {
        await wsService.disconnect()
      }
    }
  }

  @ViewBuilder
  private func notificationCard(_ notification: MilestoneNotification) -> some View {
    VStack(spacing: 12) {
      HStack {
        Image(systemName: "star.fill")
          .font(.system(size: 24))
          .foregroundColor(.yellow)

        VStack(alignment: .leading, spacing: 4) {
          Text("🎉 Milestone Reached!")
            .font(.headline)
            .fontWeight(.semibold)

          Text(notification.habitName)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()
      }

      HStack(spacing: 20) {
        VStack(alignment: .center, spacing: 4) {
          Text("\(notification.milestone)")
            .font(.system(size: 28, weight: .bold))
          Text("day streak")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Divider()

        VStack(alignment: .center, spacing: 4) {
          Text("\(notification.currentStreak)")
            .font(.system(size: 28, weight: .bold))
          Text("current")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Button(action: { showNotification = false }) {
        Text("Dismiss")
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private func handleEvent(_ event: WebSocketEvent) {
    switch event {
    case .connected:
      print("WebSocket connected")

    case .disconnected:
      print("WebSocket disconnected")

    case .subscribed:
      print("Subscribed to milestones")

    case .milestone(let notification):
      self.notification = notification
      self.showNotification = true

      DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        self.showNotification = false
      }

    case .error(let message):
      print("WebSocket error: \(message)")

    case .reconnecting(let attempt):
      print("Reconnecting (attempt \(attempt))")
    }
  }
}

#Preview {
  MilestoneNotificationView()
}
