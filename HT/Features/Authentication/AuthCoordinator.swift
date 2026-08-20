//
//  AuthCoordinator.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class AuthCoordinator: ObservableObject {
  @Published var isAuthenticated = false
  @Published var isRestoring = true
  @Published var restorationError: String?

  private let sessionManager: SessionManager
  private var cancellables = Set<AnyCancellable>()

  init(sessionManager: SessionManager = SessionManager.shared) {
    self.sessionManager = sessionManager

    // Listen to session state changes
    sessionManager.$isAuthenticated
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isAuthenticated in
        self?.isAuthenticated = isAuthenticated
      }
      .store(in: &cancellables)
  }

  func restoreSession() async {
    isRestoring = true
    restorationError = nil

    do {
      // Try to restore session from Keychain
      if let restored = try await sessionManager.restoreSessionIfAvailable() {
        // Session restored, now validate with backend
        try await validateSessionWithBackend()
        isAuthenticated = true
      } else {
        // No session found
        isAuthenticated = false
      }
    } catch {
      restorationError = error.localizedDescription
      isAuthenticated = false
    }

    isRestoring = false
  }

  private func validateSessionWithBackend() async throws {
    // TODO: Implement backend validation
    // For now, trust that if we have tokens in Keychain, the session is valid
    // In production, could check with a /auth/validate endpoint
  }

  func logout() async {
    await sessionManager.logout()
    isAuthenticated = false
  }

  func clearRestorationError() {
    restorationError = nil
  }
}
