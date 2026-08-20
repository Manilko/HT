//
//  AuthViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Combine

enum AuthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
  case error(String)

  var isLoading: Bool {
    if case .authenticating = self {
      return true
    }
    return false
  }
}

enum AuthenticationError: LocalizedError {
  case cancelled
  case authFailed(String)
  case noAuthCode
  case tokenExchangeFailed(String)
  case refreshFailed
  case noRefreshToken
  case invalidURL

  var errorDescription: String? {
    switch self {
    case .cancelled:
      return "Authentication was cancelled"
    case .authFailed(let message):
      return "Authentication failed: \(message)"
    case .noAuthCode:
      return "No authorization code received"
    case .tokenExchangeFailed(let message):
      return "Failed to exchange code for tokens: \(message)"
    case .refreshFailed:
      return "Failed to refresh authentication token"
    case .noRefreshToken:
      return "No refresh token available"
    case .invalidURL:
      return "Invalid authentication URL"
    }
  }
}

@MainActor
class AuthViewModel: ObservableObject {
  @Published var authState: AuthenticationState = .unauthenticated
  @Published var errorMessage: String?

  private let sessionManager: SessionManager
  private let authService: AuthService

  var isSignInEnabled: Bool {
    if case .authenticating = authState {
      return false
    }
    return true
  }

  init(
    sessionManager: SessionManager = SessionManager.shared,
    authService: AuthService = AuthService.shared
  ) {
    self.sessionManager = sessionManager
    self.authService = authService

    // Listen to session state changes
    sessionManager.$isAuthenticated
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isAuthenticated in
        if isAuthenticated {
          self?.authState = .authenticated
        }
      }
      .store(in: &cancellables)
  }

  private var cancellables = Set<AnyCancellable>()

  func signInWithGoogle() async {
    await performSignIn(provider: "Google") {
      await self.sessionManager.signInWithGoogle()
    }
  }

  func signInWithGitHub() async {
    await performSignIn(provider: "GitHub") {
      await self.sessionManager.signInWithGitHub()
    }
  }

  private func performSignIn(provider: String, signInAction: @escaping () async -> Void) async {
    authState = .authenticating
    errorMessage = nil

    do {
      try await withTimeout(seconds: 120) {
        await signInAction()
      }

      if sessionManager.isAuthenticated {
        authState = .authenticated
      } else {
        let errorMsg = "Failed to authenticate with \(provider). Please try again."
        authState = .error(errorMsg)
        errorMessage = errorMsg
      }
    } catch let error as AuthenticationError {
      let errorMsg = error.errorDescription ?? "Authentication failed"
      authState = .error(errorMsg)
      errorMessage = errorMsg
    } catch {
      let errorMsg = error.localizedDescription
      authState = .error(errorMsg)
      errorMessage = errorMsg
    }
  }

  func clearError() {
    errorMessage = nil
    if case .error = authState {
      authState = .unauthenticated
    }
  }

  private func withTimeout(seconds: UInt64, operation: @escaping () async -> Void) async throws {
    try await withThrowingTaskGroup(of: Void.self) { taskGroup in
      taskGroup.addTask {
        try Task.checkCancellation()
        await operation()
      }

      taskGroup.addTask {
        try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
        throw AuthenticationError.cancelled
      }

      try await taskGroup.next()
      taskGroup.cancelAll()
    }
  }
}

