//
//  LogoutServiceTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

final class LogoutServiceTests: XCTestCase {
  var sut: LogoutService!
  var mockAPIClient: MockLogoutAPIClient!
  var mockStorageManager: MockLogoutStorageManager!
  var mockWebSocketService: MockLogoutWebSocketService!

  override func setUp() {
    super.setUp()

    mockAPIClient = MockLogoutAPIClient()
    mockStorageManager = MockLogoutStorageManager()
    mockWebSocketService = MockLogoutWebSocketService()

    sut = LogoutService(
      apiClient: mockAPIClient,
      storageManager: mockStorageManager,
      webSocketService: mockWebSocketService
    )
  }

  override func tearDown() {
    sut = nil
    mockAPIClient = nil
    mockStorageManager = nil
    mockWebSocketService = nil

    super.tearDown()
  }

  // MARK: - Backend Session Invalidation

  @MainActor
  func testLogoutCallsBackendLogout() async {
    try? await sut.logout()

    XCTAssertTrue(mockAPIClient.logoutWasCalled)
  }

  @MainActor
  func testLogoutContinuesOnBackendError() async {
    mockAPIClient.logoutShouldFail = true

    do {
      try await sut.logout()
      // Should not throw even if backend logout fails
      XCTAssertTrue(mockStorageManager.accessTokenWasCleared)
    } catch {
      XCTFail("Should not throw on backend logout failure")
    }
  }

  // MARK: - WebSocket Disconnection

  @MainActor
  func testLogoutDisconnectsWebSocket() async {
    try? await sut.logout()

    XCTAssertTrue(mockWebSocketService.disconnectWasCalled)
  }

  // MARK: - Keychain Cleanup

  @MainActor
  func testLogoutClearsAccessToken() async {
    mockStorageManager.accessToken = "test-token"

    try? await sut.logout()

    XCTAssertTrue(mockStorageManager.accessTokenWasCleared)
  }

  @MainActor
  func testLogoutClearsRefreshToken() async {
    mockStorageManager.refreshToken = "refresh-token"

    try? await sut.logout()

    XCTAssertTrue(mockStorageManager.refreshTokenWasCleared)
  }

  @MainActor
  func testLogoutClearsUser() async {
    mockStorageManager.userId = 123
    mockStorageManager.userEmail = "user@example.com"

    try? await sut.logout()

    XCTAssertTrue(mockStorageManager.userWasCleared)
  }

  // MARK: - Application State

  @MainActor
  func testLogoutClearsApplicationCache() async {
    // Add data to URLCache
    let testURL = URL(string: "https://api.example.com/test")!
    let response = URLResponse(
      url: testURL,
      mimeType: "application/json",
      expectedContentLength: 0,
      textEncodingName: nil
    )
    let data = "test".data(using: .utf8)!
    let cachedResponse = CachedURLResponse(response: response, data: data)

    URLCache.shared.storeCachedResponse(cachedResponse, for: URLRequest(url: testURL))

    XCTAssertNotNil(URLCache.shared.cachedResponse(for: URLRequest(url: testURL)))

    try? await sut.logout()

    XCTAssertNil(URLCache.shared.cachedResponse(for: URLRequest(url: testURL)))
  }

  // MARK: - Complete Logout Sequence

  @MainActor
  func testCompleteLogoutSequence() async {
    mockStorageManager.accessToken = "token"
    mockStorageManager.refreshToken = "refresh"
    mockStorageManager.userId = 1
    mockStorageManager.userEmail = "test@example.com"

    try? await sut.logout()

    // Verify all cleanup happened
    XCTAssertTrue(mockAPIClient.logoutWasCalled)
    XCTAssertTrue(mockWebSocketService.disconnectWasCalled)
    XCTAssertTrue(mockStorageManager.accessTokenWasCleared)
    XCTAssertTrue(mockStorageManager.refreshTokenWasCleared)
    XCTAssertTrue(mockStorageManager.userWasCleared)
  }

  // MARK: - State Verification After Logout

  @MainActor
  func testNoDataRemainsAfterLogout() async {
    mockStorageManager.accessToken = "token"
    mockStorageManager.userId = 123

    try? await sut.logout()

    XCTAssertNil(mockStorageManager.accessToken)
    XCTAssertNil(mockStorageManager.userId)
  }

  @MainActor
  func testWebSocketDisconnectedAfterLogout() async {
    try? await sut.logout()

    XCTAssertTrue(mockWebSocketService.disconnectWasCalled)
    XCTAssertFalse(mockWebSocketService.isConnected)
  }
}

// MARK: - Mocks

class MockLogoutAPIClient: APIClient {
  var logoutWasCalled = false
  var logoutShouldFail = false

  override func request<T: Decodable>(
    endpoint: String,
    method: HTTPMethod,
    body: Encodable?
  ) async throws -> T {
    if endpoint == "/auth/logout" && method == .post {
      logoutWasCalled = true

      if logoutShouldFail {
        throw NSError(domain: "MockError", code: 1, userInfo: nil)
      }

      return EmptyResponse() as! T
    }

    throw NSError(domain: "MockError", code: 1)
  }
}

class MockLogoutStorageManager: StorageManager {
  var accessToken: String?
  var refreshToken: String?
  var userId: Int?
  var userEmail: String?

  var accessTokenWasCleared = false
  var refreshTokenWasCleared = false
  var userWasCleared = false

  override func getAccessToken() -> String? {
    accessToken
  }

  override func saveAccessToken(_ token: String) {
    accessToken = token
  }

  override func clearAccessToken() {
    accessToken = nil
    accessTokenWasCleared = true
  }

  override func getRefreshToken() -> String? {
    refreshToken
  }

  override func saveRefreshToken(_ token: String) {
    refreshToken = token
  }

  override func clearRefreshToken() {
    refreshToken = nil
    refreshTokenWasCleared = true
  }

  override func getUserId() -> Int? {
    userId
  }

  override func saveUserId(_ id: Int) {
    userId = id
  }

  override func getUserEmail() -> String? {
    userEmail
  }

  override func saveUserEmail(_ email: String) {
    userEmail = email
  }

  override func clearUser() {
    userId = nil
    userEmail = nil
    userWasCleared = true
  }
}

class MockLogoutWebSocketService: WebSocketService {
  var disconnectWasCalled = false
  var isConnected = true

  override func disconnect() async {
    disconnectWasCalled = true
    isConnected = false
  }
}
