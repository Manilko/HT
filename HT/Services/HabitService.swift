//
//  HabitService.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

class HabitService {
  nonisolated(unsafe) static let shared = HabitService()

  private let apiClient: APIClient

  nonisolated private init(apiClient: APIClient = .shared) {
    self.apiClient = apiClient
  }

  @MainActor
  func fetchHabits() async throws -> [Habit] {
    let response: APIResponse<[Habit]> = try await apiClient.request(endpoint: "/habits")
    return response.data ?? []
  }

  @MainActor
  func fetchHabit(_ habitId: Int) async throws -> Habit {
    let response: APIResponse<Habit> = try await apiClient.request(endpoint: "/habits/\(habitId)")
    guard let habit = response.data else {
      throw APIError.notFound
    }
    return habit
  }

  @MainActor
  func createHabit(name: String, description: String?, color: String?) async throws -> Habit {
    let body = CreateHabitRequest(name: name, description: description, color: color)
    let response: APIResponse<Habit> = try await apiClient.request(
      endpoint: "/habits",
      method: .post,
      body: body
    )
    guard let habit = response.data else {
      throw APIError.unknown
    }
    return habit
  }

  @MainActor
  func updateHabit(_ habit: Habit) async throws -> Habit {
    let body = UpdateHabitRequest(
      name: habit.name,
      description: habit.description,
      color: habit.color
    )
    let response: APIResponse<Habit> = try await apiClient.request(
      endpoint: "/habits/\(habit.id)",
      method: .patch,
      body: body
    )
    guard let updatedHabit = response.data else {
      throw APIError.unknown
    }
    return updatedHabit
  }

  @MainActor
  func deleteHabit(_ habitId: Int) async throws {
    let _: APIResponse<EmptyResponse> = try await apiClient.request(
      endpoint: "/habits/\(habitId)",
      method: .delete
    )
  }

  @MainActor
  func logCheckIn(habitId: Int, notes: String?) async throws -> CheckIn {
    let body = LogCheckInRequest(notes: notes)
    let response: APIResponse<CheckIn> = try await apiClient.request(
      endpoint: "/habits/\(habitId)/check-in",
      method: .post,
      body: body
    )
    guard let checkIn = response.data else {
      throw APIError.unknown
    }
    return checkIn
  }

  @MainActor
  func fetchStreak(_ habitId: Int) async throws -> Streak {
    let response: APIResponse<Streak> = try await apiClient.request(
      endpoint: "/habits/\(habitId)/streak"
    )
    guard let streak = response.data else {
      throw APIError.notFound
    }
    return streak
  }
}

// MARK: - Request Models

struct CreateHabitRequest: Encodable {
  let name: String
  let description: String?
  let color: String?
}

struct UpdateHabitRequest: Encodable {
  let name: String
  let description: String?
  let color: String?
}

struct LogCheckInRequest: Encodable {
  let notes: String?
}

struct EmptyResponse: Decodable {}
