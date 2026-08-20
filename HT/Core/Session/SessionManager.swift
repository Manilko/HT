//
//  SessionManager.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Combine

@MainActor
class SessionManager: ObservableObject {
  static let shared = SessionManager()

  @Published var isAuthenticated = false
  @Published var currentUser: AuthenticationResponse.User?
  @Published var error: Error?

  private let authService: AuthService
  private let storageManager: StorageManager
  private var tokenRefreshTimer: Timer?
  private let tokenRefreshThreshold: TimeInterval = 300 // Refresh if less than 5 minutes left

  nonisolated private init() {
    self.authService = AuthService.shared
    self.storageManager = StorageManager.shared
  }

  // MARK: - Session Lifecycle

  func initializeSession() async {
    do {
      if let restored = try await authService.restoreSessionIfAvailable() {
        await MainActor.run {
          self.isAuthenticated = true
          self.currentUser = restored.user
        }
        scheduleTokenRefresh()
      } else {
        await MainActor.run {
          self.isAuthenticated = false
          self.currentUser = nil
        }
      }
    } catch {
      await MainActor.run {
        self.error = error
        self.isAuthenticated = false
      }
    }
  }

  func signInWithGoogle() async {
    do {
      let response = try await authService.signInWithGoogle()
      await MainActor.run {
        self.isAuthenticated = true
        self.currentUser = response.user
        self.error = nil
      }
      scheduleTokenRefresh()
    } catch {
      await MainActor.run {
        self.error = error
        self.isAuthenticated = false
      }
    }
  }

  func signInWithGitHub() async {
    do {
      let response = try await authService.signInWithGitHub()
      await MainActor.run {
        self.isAuthenticated = true
        self.currentUser = response.user
        self.error = nil
      }
      scheduleTokenRefresh()
    } catch {
      await MainActor.run {
        self.error = error
        self.isAuthenticated = false
      }
    }
  }

  func logout() async {
    do {
      try await authService.logout()
      await MainActor.run {
        self.isAuthenticated = false
        self.currentUser = nil
        self.error = nil
      }
      invalidateTokenRefreshTimer()
    } catch {
      await MainActor.run {
        self.error = error
      }
    }
  }

  // MARK: - Token Refresh

  private func scheduleTokenRefresh() {
    invalidateTokenRefreshTimer()

    // Refresh token every 10 minutes (before 15-minute expiry)
    let refreshInterval: TimeInterval = 600 // 10 minutes

    tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
      Task {
        await self.performTokenRefresh()
      }
    }
  }

  private func invalidateTokenRefreshTimer() {
    tokenRefreshTimer?.invalidate()
    tokenRefreshTimer = nil
  }

  private func performTokenRefresh() async {
    do {
      try await authService.refreshTokenIfNeeded()
    } catch {
      // Token refresh failed - user will need to re-authenticate
      await logout()
    }
  }

  // MARK: - Accessors

  func getAccessToken() -> String? {
    return storageManager.accessToken
  }

  func getUserID() -> Int? {
    return storageManager.getUserID()
  }
}
