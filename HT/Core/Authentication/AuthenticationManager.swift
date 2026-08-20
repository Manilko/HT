//
//  AuthenticationManager.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Combine

@MainActor
class AuthenticationManager: ObservableObject {
  static let shared = AuthenticationManager()

  @Published var isAuthenticating = false
  @Published var authError: Error?

  private let storageManager: StorageManager
  private let apiClient: APIClient

  nonisolated private init(
    storageManager: StorageManager = StorageManager.shared,
    apiClient: APIClient = APIClient.shared
  ) {
    self.storageManager = storageManager
    self.apiClient = apiClient
  }

  func isAuthenticated() -> Bool {
    return storageManager.accessToken != nil
  }

  func getAccessToken() -> String? {
    return storageManager.accessToken
  }

  func signInWithGoogle() async throws {
    isAuthenticating = true
    defer { isAuthenticating = false }

    // TODO: Implement Google OAuth flow
    // For now, mock implementation
    await MainActor.run {
      self.storageManager.saveAccessToken("mock_token_google")
      self.storageManager.saveRefreshToken("mock_refresh_token_google")
    }
  }

  func signInWithGitHub() async throws {
    isAuthenticating = true
    defer { isAuthenticating = false }

    // TODO: Implement GitHub OAuth flow
    // For now, mock implementation
    await MainActor.run {
      self.storageManager.saveAccessToken("mock_token_github")
      self.storageManager.saveRefreshToken("mock_refresh_token_github")
    }
  }

  func logout() async throws {
    // TODO: Revoke tokens on backend if needed
    await MainActor.run {
      self.storageManager.clearAllTokens()
    }
  }

  func refreshTokenIfNeeded() async throws {
    guard let refreshToken = storageManager.refreshToken else {
      throw AuthenticationError.noRefreshToken
    }

    // TODO: Call backend refresh endpoint
    // For now, mock implementation
  }
}

enum AuthenticationError: LocalizedError {
  case noRefreshToken
  case invalidCredentials
  case networkError
  case unknown

  var errorDescription: String? {
    switch self {
    case .noRefreshToken:
      return "No refresh token available"
    case .invalidCredentials:
      return "Invalid credentials"
    case .networkError:
      return "Network error"
    case .unknown:
      return "Unknown error"
    }
  }
}
