//
//  HabitServiceProtocol.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

protocol HabitServiceProtocol: AnyObject {
  func fetchHabits() async throws -> [Habit]
  func searchHabits(query: String) async throws -> [Habit]
  func createHabit(name: String, description: String?, color: String?) async throws -> Habit
  func updateHabit(_ habit: Habit) async throws -> Habit
  func deleteHabit(_ habitId: Int) async throws

  func logCheckIn(habitId: Int, notes: String?) async throws -> CheckIn
  func deleteCheckIn(habitId: Int, date: String) async throws
  func fetchCheckIns(habitId: Int) async throws -> [CheckIn]

  func fetchStreak(habitId: Int) async throws -> Streak
}

class MockHabitService: HabitServiceProtocol {
  func fetchHabits() async throws -> [Habit] {
    []
  }

  func searchHabits(query: String) async throws -> [Habit] {
    []
  }

  func createHabit(name: String, description: String?, color: String?) async throws -> Habit {
    throw NSError(domain: "mock", code: 0)
  }

  func updateHabit(_ habit: Habit) async throws -> Habit {
    habit
  }

  func deleteHabit(_ habitId: Int) async throws {
    // Mock
  }

  func logCheckIn(habitId: Int, notes: String?) async throws -> CheckIn {
    throw NSError(domain: "mock", code: 0)
  }

  func deleteCheckIn(habitId: Int, date: String) async throws {
    // Mock
  }

  func fetchCheckIns(habitId: Int) async throws -> [CheckIn] {
    []
  }

  func fetchStreak(habitId: Int) async throws -> Streak {
    throw NSError(domain: "mock", code: 0)
  }
}
