//
//  UserService.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

class UserService {
  nonisolated(unsafe) static let shared = UserService()

  private let apiClient: APIClient
  private let storageManager: StorageManager

  nonisolated private init(apiClient: APIClient = .shared, storageManager: StorageManager = .shared) {
    self.apiClient = apiClient
    self.storageManager = storageManager
  }

  @MainActor
  func fetchCurrentUser() async throws -> User {
    let response: APIResponse<User> = try await apiClient.request(endpoint: "/users/me")
    guard let user = response.data else {
      throw APIError.notFound
    }
    storageManager.saveUserID(user.id)
    return user
  }

  @MainActor
  func updateTimezone(_ timezone: String) async throws -> User {
    let body = UpdateTimezoneRequest(timezone: timezone)
    let response: APIResponse<User> = try await apiClient.request(
      endpoint: "/users/me",
      method: .patch,
      body: body
    )
    guard let user = response.data else {
      throw APIError.unknown
    }
    return user
  }

  @MainActor
  func updateProfile(displayName: String) async throws -> User {
    let body = UpdateProfileRequest(displayName: displayName)
    let response: APIResponse<User> = try await apiClient.request(
      endpoint: "/users/me",
      method: .patch,
      body: body
    )
    guard let user = response.data else {
      throw APIError.unknown
    }
    return user
  }

  @MainActor
  func deleteAccount() async throws {
    let _: APIResponse<EmptyResponse> = try await apiClient.request(
      endpoint: "/users/me",
      method: .delete
    )
  }
}

// MARK: - Request Models

struct UpdateTimezoneRequest: Encodable {
  let timezone: String
}

struct UpdateProfileRequest: Encodable {
  let displayName: String

  enum CodingKeys: String, CodingKey {
    case displayName = "display_name"
  }
}
