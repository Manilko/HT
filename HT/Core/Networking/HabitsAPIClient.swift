//
//  HabitsAPIClient.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

class HabitsAPIClient {
  private let apiClient: APIClient

  init(apiClient: APIClient = .shared) {
    self.apiClient = apiClient
  }

  func listHabits() async throws -> [Habit] {
    struct HabitsResponse: Decodable {
      let success: Bool
      let data: HabitsData

      struct HabitsData: Decodable {
        let habits: [HabitDTO]
      }
    }

    let response: HabitsResponse = try await apiClient.request(
      endpoint: "/habits",
      method: .get
    )

    return response.data.habits.map { $0.toHabit() }
  }

  func getHabit(id: Int) async throws -> Habit {
    struct HabitResponse: Decodable {
      let success: Bool
      let data: HabitDTO
    }

    let response: HabitResponse = try await apiClient.request(
      endpoint: "/habits/\(id)",
      method: .get
    )

    return response.data.toHabit()
  }

  func createHabit(name: String, description: String?, startDate: String) async throws -> Habit {
    struct HabitResponse: Decodable {
      let success: Bool
      let data: HabitDTO
    }

    let request = CreateHabitRequest(
      name: name,
      description: description,
      startDate: startDate
    )

    let response: HabitResponse = try await apiClient.request(
      endpoint: "/habits",
      method: .post,
      body: request
    )

    return response.data.toHabit()
  }

  func updateHabit(id: Int, name: String? = nil, description: String? = nil, status: HabitStatus? = nil) async throws -> Habit {
    struct HabitResponse: Decodable {
      let success: Bool
      let data: HabitDTO
    }

    let request = UpdateHabitRequest(name: name, description: description, status: status)

    let response: HabitResponse = try await apiClient.request(
      endpoint: "/habits/\(id)",
      method: .patch,
      body: request
    )

    return response.data.toHabit()
  }

  func deleteHabit(id: Int) async throws {
    struct DeleteResponse: Decodable {
      let success: Bool
    }

    let _: DeleteResponse = try await apiClient.request(
      endpoint: "/habits/\(id)",
      method: .delete
    )
  }

  func archiveHabit(id: Int) async throws -> Habit {
    try await updateHabit(id: id, status: .archived)
  }

  func pauseHabit(id: Int) async throws -> Habit {
    try await updateHabit(id: id, status: .paused)
  }

  func resumeHabit(id: Int) async throws -> Habit {
    try await updateHabit(id: id, status: .active)
  }
}
