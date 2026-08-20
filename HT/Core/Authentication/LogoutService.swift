//
//  LogoutService.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

@MainActor
class LogoutService {
  private let apiClient: APIClient
  private let storageManager: StorageManager
  private let webSocketService: WebSocketService

  init(
    apiClient: APIClient = .shared,
    storageManager: StorageManager = StorageManager.shared,
    webSocketService: WebSocketService = WebSocketService()
  ) {
    self.apiClient = apiClient
    self.storageManager = storageManager
    self.webSocketService = webSocketService
  }

  func logout() async throws {
    // 1. Invalidate backend session
    await invalidateBackendSession()

    // 2. Disconnect WebSocket
    await webSocketService.disconnect()

    // 3. Clear Keychain authentication data
    clearAuthenticationData()

    // 4. Clear user-specific application state
    clearApplicationState()
  }

  private func invalidateBackendSession() async {
    do {
      struct LogoutRequest: Encodable {
        let timestamp: String
      }

      let request = LogoutRequest(
        timestamp: ISO8601DateFormatter().string(from: Date())
      )

      let _: EmptyResponse = try await apiClient.request(
        endpoint: "/auth/logout",
        method: .post,
        body: request
      )

      print("✓ Backend session invalidated")
    } catch {
      print("⚠ Failed to invalidate backend session: \(error.localizedDescription)")
      // Continue with local cleanup even if backend logout fails
    }
  }

  private func clearAuthenticationData() {
    storageManager.clearAccessToken()
    storageManager.clearRefreshToken()
    storageManager.clearUser()

    print("✓ Keychain cleared")
  }

  private func clearApplicationState() {
    // Clear any cached data that might contain user information
    URLCache.shared.removeAllCachedResponses()

    // Clear in-memory caches
    NSURLCache.shared.removeAllCachedResponses()

    print("✓ Application state cleared")
  }
}

// MARK: - Empty Response for Logout

struct EmptyResponse: Decodable {}
