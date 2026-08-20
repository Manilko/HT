//
//  ToastView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct ToastView: View {
  let notification: ToastNotification
  @State private var isShowing = false
  @EnvironmentObject private var notificationStore: NotificationStore

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 12) {
        Text(notification.type.icon)
          .font(.system(size: 24))

        VStack(alignment: .leading, spacing: 4) {
          Text(notification.title)
            .font(.headline)
            .fontWeight(.semibold)

          Text(notification.message)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        Spacer()

        Button(action: {
          notificationStore.dismiss(notification.id)
        }) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
        }
      }

      ProgressView(value: 1.0)
        .scaleEffect(y: 0.5, anchor: .bottom)
        .onAppear {
          animateProgressBar()
        }
    }
    .padding()
    .background(backgroundColor)
    .cornerRadius(12)
    .shadow(radius: 4)
    .padding()
    .transition(.move(edge: .top).combined(with: .opacity))
  }

  private var backgroundColor: Color {
    switch notification.type {
    case .milestone:
      return Color.orange.opacity(0.95)
    case .success:
      return Color.green.opacity(0.95)
    case .error:
      return Color.red.opacity(0.95)
    case .info:
      return Color.blue.opacity(0.95)
    }
  }

  private func animateProgressBar() {
    withAnimation(.linear(duration: notification.duration)) {
      // Progress bar animation handled by ProgressView
    }
  }
}

struct ToastContainerView: View {
  @StateObject private var notificationStore = NotificationStore()

  var body: some View {
    ZStack(alignment: .top) {
      Color.clear

      if let notification = notificationStore.currentNotification {
        ToastView(notification: notification)
          .environmentObject(notificationStore)
      }
    }
    .frame(height: 0)
  }
}

#Preview {
  VStack {
    ToastView(
      notification: ToastNotification.milestone(
        MilestoneNotification(
          habitId: 1,
          habitName: "Morning Run",
          milestone: 3,
          currentStreak: 3
        )
      )
    )
    .environmentObject(NotificationStore())

    Spacer()
  }
}
