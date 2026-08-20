//
//  CheckInsAPIClient.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

class CheckInsAPIClient {
  private let apiClient: APIClient

  init(apiClient: APIClient = .shared) {
    self.apiClient = apiClient
  }

  func checkInToday(habitId: Int) async throws -> CheckIn {
    struct CheckInResponse: Decodable {
      let success: Bool
      let data: CheckIn
    }

    let response: CheckInResponse = try await apiClient.request(
      endpoint: "/habits/\(habitId)/check-ins",
      method: .post
    )

    return response.data
  }

  func getCheckIns(habitId: Int) async throws -> [CheckIn] {
    struct CheckInsResponse: Decodable {
      let success: Bool
      let data: CheckInsData

      struct CheckInsData: Decodable {
        let checkIns: [CheckIn]
      }
    }

    let response: CheckInsResponse = try await apiClient.request(
      endpoint: "/habits/\(habitId)/check-ins",
      method: .get
    )

    return response.data.checkIns
  }

  func undoTodaysCheckIn(habitId: Int) async throws {
    struct DeleteResponse: Decodable {
      let success: Bool
    }

    let _: DeleteResponse = try await apiClient.request(
      endpoint: "/habits/\(habitId)/check-ins/today",
      method: .delete
    )
  }
}
