//
//  ToastNotification.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

struct ToastNotification: Identifiable, Equatable {
  let id: UUID
  let title: String
  let message: String
  let type: NotificationType
  let duration: TimeInterval

  enum NotificationType: Equatable {
    case milestone(days: Int)
    case success
    case error
    case info

    var icon: String {
      switch self {
      case .milestone:
        return "🔥"
      case .success:
        return "✓"
      case .error:
        return "✕"
      case .info:
        return "ℹ"
      }
    }

    var backgroundColor: String {
      switch self {
      case .milestone:
        return "orange"
      case .success:
        return "green"
      case .error:
        return "red"
      case .info:
        return "blue"
      }
    }
  }

  init(
    title: String,
    message: String,
    type: NotificationType,
    duration: TimeInterval = 4.0
  ) {
    self.id = UUID()
    self.title = title
    self.message = message
    self.type = type
    self.duration = duration
  }

  static func milestone(_ notification: MilestoneNotification) -> ToastNotification {
    let emoji: String
    let daysText: String

    switch notification.milestone {
    case 3:
      emoji = "🔥"
      daysText = "3-day"
    case 7:
      emoji = "⭐"
      daysText = "7-day"
    case 30:
      emoji = "🏆"
      daysText = "30-day"
    default:
      emoji = "🎉"
      daysText = "\(notification.milestone)-day"
    }

    let title = "\(emoji) \(daysText) streak!"
    let message = "You completed \"\(notification.habitName)\" for \(notification.milestone) consecutive days."

    return ToastNotification(
      title: title,
      message: message,
      type: .milestone(days: notification.milestone),
      duration: 5.0
    )
  }
}
