//
//  AuthService.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import AuthenticationServices
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class AuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
  static let shared = AuthService()

  private let apiClient: APIClient
  private let storageManager: StorageManager
  private var authSession: ASWebAuthenticationSession?

  nonisolated private override init() {
    self.apiClient = APIClient.shared
    self.storageManager = StorageManager.shared
  }

  // MARK: - OAuth Flow

  func signInWithGoogle() async throws -> AuthenticationResponse {
    let authCode = try await requestAuthorizationCode(
      provider: "google",
      scope: "openid profile email"
    )

    return try await exchangeCodeForTokens(code: authCode, provider: "google")
  }

  func signInWithGitHub() async throws -> AuthenticationResponse {
    let authCode = try await requestAuthorizationCode(
      provider: "github",
      scope: "user:email"
    )

    return try await exchangeCodeForTokens(code: authCode, provider: "github")
  }

  private func requestAuthorizationCode(provider: String, scope: String) async throws -> String {
    let authorizationEndpoint = URL(string: "https://\(provider).com/o/oauth2/v2/auth")!
    var components = URLComponents(url: authorizationEndpoint, resolvingAgainstBaseURL: true)!

    components.queryItems = [
      URLQueryItem(name: "client_id", value: getClientId(for: provider)),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "scope", value: scope),
      URLQueryItem(name: "redirect_uri", value: "habittracker://oauth-callback"),
      URLQueryItem(name: "prompt", value: "consent"),
    ]

    guard let authUrl = components.url else {
      throw OAuthError.invalidURL
    }

    return try await withCheckedThrowingContinuation { continuation in
      let session = ASWebAuthenticationSession(
        url: authUrl,
        callbackURLScheme: "habittracker"
      ) { callbackUrl, error in
        if let error = error {
          if case ASWebAuthenticationSessionError.canceledLogin = error as? ASWebAuthenticationSessionError {
            continuation.resume(throwing: OAuthError.cancelled)
          } else {
            continuation.resume(throwing: OAuthError.authFailed(error.localizedDescription))
          }
          return
        }

        guard let callbackUrl = callbackUrl,
              let components = URLComponents(url: callbackUrl, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
          continuation.resume(throwing: OAuthError.noAuthCode)
          return
        }

        continuation.resume(returning: code)
      }

      session.presentationContextProvider = self
      self.authSession = session
      session.start()
    }
  }

  private func exchangeCodeForTokens(code: String, provider: String) async throws -> AuthenticationResponse {
    struct TokenRequest: Encodable {
      let code: String
    }

    struct TokenResponse: Decodable {
      let success: Bool
      let data: AuthenticationResponse?
      let error: ErrorDetail?

      struct ErrorDetail: Decodable {
        let code: String
        let message: String
      }
    }

    let endpoint = "/auth/\(provider)/callback"
    let request = TokenRequest(code: code)

    let response: TokenResponse = try await apiClient.request(
      endpoint: endpoint,
      method: .post,
      body: request
    )

    guard response.success, let data = response.data else {
      let errorMsg = response.error?.message ?? "Authentication failed"
      throw OAuthError.tokenExchangeFailed(errorMsg)
    }

    // Save tokens to Keychain
    storageManager.saveAccessToken(data.accessToken)
    storageManager.saveRefreshToken(data.refreshToken)
    storageManager.saveUserID(data.user.id)

    return data
  }

  // MARK: - Session Restoration

  func restoreSessionIfAvailable() async throws -> AuthenticationResponse? {
    guard let accessToken = storageManager.accessToken,
          let userId = storageManager.getUserID() else {
      return nil
    }

    // Verify token is still valid by making a health check or getting current user
    // For now, trust that if we have a token, we're authenticated
    // TODO: Implement token refresh before expiry

    // Return minimal user response (would be enhanced with actual user data from backend)
    return AuthenticationResponse(
      accessToken: accessToken,
      refreshToken: storageManager.refreshToken ?? "",
      user: AuthenticationResponse.User(
        id: userId,
        email: nil,
        displayName: "User",
        avatarUrl: nil
      )
    )
  }

  func logout() async throws {
    // Call backend logout endpoint (for future token blacklisting)
    try await apiClient.request(endpoint: "/auth/logout", method: .post) as EmptyResponse

    // Clear local tokens
    storageManager.clearAllTokens()
  }

  // MARK: - Token Refresh

  func refreshTokenIfNeeded() async throws {
    guard let refreshToken = storageManager.refreshToken else {
      throw OAuthError.noRefreshToken
    }

    struct RefreshRequest: Encodable {
      let refreshToken: String
    }

    struct RefreshResponse: Decodable {
      let success: Bool
      let data: RefreshData?

      struct RefreshData: Decodable {
        let accessToken: String
      }
    }

    let request = RefreshRequest(refreshToken: refreshToken)
    let response: RefreshResponse = try await apiClient.request(
      endpoint: "/auth/refresh",
      method: .post,
      body: request
    )

    guard response.success, let data = response.data else {
      throw OAuthError.refreshFailed
    }

    storageManager.saveAccessToken(data.accessToken)
  }

  // MARK: - Helpers

  private func getClientId(for provider: String) -> String {
    // These should come from Info.plist or environment
    switch provider {
    case "google":
      return "YOUR_GOOGLE_CLIENT_ID"
    case "github":
      return "YOUR_GITHUB_CLIENT_ID"
    default:
      return ""
    }
  }

  // MARK: - ASWebAuthenticationPresentationContextProviding

  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene
    let window = windowScene?.windows.first { $0.isKeyWindow } ?? windowScene?.windows.first
    return window ?? ASPresentationAnchor()
  }
}

// MARK: - Response Models

struct AuthenticationResponse: Decodable {
  let accessToken: String
  let refreshToken: String
  let user: User

  struct User: Decodable {
    let id: Int
    let email: String?
    let displayName: String
    let avatarUrl: String?
  }
}

struct EmptyResponse: Decodable {
  let success: Bool
}

// MARK: - Errors

enum OAuthError: LocalizedError {
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
      return "Failed to refresh token"
    case .noRefreshToken:
      return "No refresh token available"
    case .invalidURL:
      return "Invalid authorization URL"
    }
  }
}
