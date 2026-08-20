//
//  WebSocketEvent.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

enum WebSocketEvent: Equatable {
  case connected
  case disconnected
  case subscribed
  case milestone(MilestoneNotification)
  case error(String)
  case reconnecting(attempt: Int)
}

extension WebSocketEvent: Hashable {
  func hash(into hasher: inout Hasher) {
    switch self {
    case .connected:
      hasher.combine("connected")
    case .disconnected:
      hasher.combine("disconnected")
    case .subscribed:
      hasher.combine("subscribed")
    case .milestone(let notification):
      hasher.combine("milestone")
      hasher.combine(notification.habitId)
      hasher.combine(notification.milestone)
    case .error(let message):
      hasher.combine("error")
      hasher.combine(message)
    case .reconnecting(let attempt):
      hasher.combine("reconnecting")
      hasher.combine(attempt)
    }
  }
}
