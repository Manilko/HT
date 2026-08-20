//
//  WebSocketServiceProtocol.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

protocol WebSocketServiceProtocol: AnyObject {
  func connect() async throws
  func disconnect() async
  func subscribe(toHabitId habitId: Int) async throws
  func unsubscribe(fromHabitId habitId: Int) async throws
  func onMilestoneReached(_ callback: @escaping (Int, Int) -> Void)
}

class MockWebSocketService: WebSocketServiceProtocol {
  func connect() async throws {
    // Mock
  }

  func disconnect() async {
    // Mock
  }

  func subscribe(toHabitId habitId: Int) async throws {
    // Mock
  }

  func unsubscribe(fromHabitId habitId: Int) async throws {
    // Mock
  }

  func onMilestoneReached(_ callback: @escaping (Int, Int) -> Void) {
    // Mock
  }
}
