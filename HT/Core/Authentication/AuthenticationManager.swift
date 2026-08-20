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
  @Published var isAuthenticated = false

  private let sessionManager: SessionManager
  private let storageManager: StorageManager

  nonisolated private init(
    sessionManager: SessionManager = SessionManager.shared,
    storageManager: StorageManager = StorageManager.shared
  ) {
    self.sessionManager = sessionManager
    self.storageManager = storageManager
  }

  func signInWithGoogle() async {
    isAuthenticating = true
    defer { isAuthenticating = false }

    await sessionManager.signInWithGoogle()

    isAuthenticated = sessionManager.isAuthenticated
    authError = sessionManager.error
  }

  func signInWithGitHub() async {
    isAuthenticating = true
    defer { isAuthenticating = false }

    await sessionManager.signInWithGitHub()

    isAuthenticated = sessionManager.isAuthenticated
    authError = sessionManager.error
  }

  func logout() async {
    await sessionManager.logout()
    isAuthenticated = sessionManager.isAuthenticated
  }

  func getAccessToken() -> String? {
    return storageManager.accessToken
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
