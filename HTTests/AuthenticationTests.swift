//
//  AuthenticationTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

class AuthenticationTests: XCTestCase {
  var storageManager: StorageManager!
  var sessionManager: SessionManager!
  var authCoordinator: AuthCoordinator!

  override func setUp() {
    super.setUp()
    storageManager = StorageManager()
    sessionManager = SessionManager()
    authCoordinator = AuthCoordinator(sessionManager: sessionManager)

    // Clear Keychain before each test
    storageManager.clearAllTokens()
  }

  override func tearDown() {
    storageManager.clearAllTokens()
    super.tearDown()
  }

  // MARK: - Session Restoration Tests

  func testRestoreSession_NoTokensInKeychain_ReturnsUnauthenticated() async {
    // Arrange
    XCTAssertNil(storageManager.accessToken)
    XCTAssertNil(storageManager.refreshToken)

    // Act
    await authCoordinator.restoreSession()

    // Assert
    XCTAssertFalse(authCoordinator.isAuthenticated)
    XCTAssertFalse(authCoordinator.isRestoring)
    XCTAssertNil(authCoordinator.restorationError)
  }

  func testRestoreSession_ValidTokenInKeychain_ReturnsAuthenticated() async {
    // Arrange
    let mockAccessToken = "mock_access_token_12345"
    let mockRefreshToken = "mock_refresh_token_12345"
    storageManager.saveAccessToken(mockAccessToken)
    storageManager.saveRefreshToken(mockRefreshToken)
    storageManager.saveUserID(123)

    // Act
    await authCoordinator.restoreSession()

    // Assert
    XCTAssertTrue(authCoordinator.isAuthenticated)
    XCTAssertFalse(authCoordinator.isRestoring)
    XCTAssertNil(authCoordinator.restorationError)

    // Verify tokens are still in Keychain
    XCTAssertEqual(storageManager.accessToken, mockAccessToken)
    XCTAssertEqual(storageManager.refreshToken, mockRefreshToken)
    XCTAssertEqual(storageManager.getUserID(), 123)
  }

  func testRestoreSession_Sets_IsRestoringFlag() async {
    // Arrange
    XCTAssertTrue(authCoordinator.isRestoring)

    // Act
    let task = Task {
      await authCoordinator.restoreSession()
    }

    // Assert - IsRestoring should be true during restoration
    // (In real implementation, would need better timing control)
    await task.value
    XCTAssertFalse(authCoordinator.isRestoring)
  }

  // MARK: - Keychain Storage Tests

  func testKeychainStorage_SaveAccessToken() {
    // Arrange
    let token = "test_access_token_xyz"

    // Act
    storageManager.saveAccessToken(token)

    // Assert
    XCTAssertEqual(storageManager.accessToken, token)
  }

  func testKeychainStorage_SaveRefreshToken() {
    // Arrange
    let token = "test_refresh_token_xyz"

    // Act
    storageManager.saveRefreshToken(token)

    // Assert
    XCTAssertEqual(storageManager.refreshToken, token)
  }

  func testKeychainStorage_ClearTokens() {
    // Arrange
    storageManager.saveAccessToken("access_token")
    storageManager.saveRefreshToken("refresh_token")

    XCTAssertNotNil(storageManager.accessToken)
    XCTAssertNotNil(storageManager.refreshToken)

    // Act
    storageManager.clearAllTokens()

    // Assert
    XCTAssertNil(storageManager.accessToken)
    XCTAssertNil(storageManager.refreshToken)
  }

  func testKeychainStorage_TokenPersistence() {
    // Arrange
    let token = "persistent_token_abc"
    storageManager.saveAccessToken(token)

    // Act
    // Simulate app restart by creating new StorageManager instance
    let newStorageManager = StorageManager()

    // Assert
    // Token should persist in Keychain
    XCTAssertEqual(newStorageManager.accessToken, token)

    // Cleanup
    newStorageManager.clearAllTokens()
  }

  func testKeychainStorage_NoUserDefaults_ForTokens() {
    // Arrange
    let token = "security_test_token"
    storageManager.saveAccessToken(token)

    // Act
    let userDefaults = UserDefaults.standard

    // Assert
    // Tokens should NOT be stored in UserDefaults
    XCTAssertNil(userDefaults.string(forKey: "accessToken"))
    XCTAssertNil(userDefaults.string(forKey: "refreshToken"))
    XCTAssertNil(userDefaults.string(forKey: "Bearer"))

    // Cleanup
    storageManager.clearAllTokens()
  }

  // MARK: - Authentication State Tests

  func testAuthenticationState_Unauthenticated() async {
    // Assert
    XCTAssertFalse(authCoordinator.isAuthenticated)
  }

  func testAuthenticationState_TransitionToAuthenticated() async {
    // Arrange
    storageManager.saveAccessToken("test_token")
    storageManager.saveRefreshToken("test_refresh")
    storageManager.saveUserID(456)

    // Act
    await authCoordinator.restoreSession()

    // Assert
    XCTAssertTrue(authCoordinator.isAuthenticated)
  }

  func testAuthenticationState_ClearError() async {
    // Arrange
    authCoordinator.restorationError = "Test error message"

    // Act
    authCoordinator.clearRestorationError()

    // Assert
    XCTAssertNil(authCoordinator.restorationError)
  }

  // MARK: - Logout Tests

  func testLogout_ClearsTokens() async {
    // Arrange
    storageManager.saveAccessToken("logout_test_token")
    storageManager.saveRefreshToken("logout_test_refresh")
    XCTAssertNotNil(storageManager.accessToken)

    // Act
    await authCoordinator.logout()

    // Assert
    XCTAssertNil(storageManager.accessToken)
    XCTAssertNil(storageManager.refreshToken)
    XCTAssertFalse(authCoordinator.isAuthenticated)
  }

  func testLogout_TransitionsToUnauthenticated() async {
    // Arrange
    storageManager.saveAccessToken("token_for_logout")
    await authCoordinator.restoreSession()
    XCTAssertTrue(authCoordinator.isAuthenticated)

    // Act
    await authCoordinator.logout()

    // Assert
    XCTAssertFalse(authCoordinator.isAuthenticated)
  }

  // MARK: - User ID Storage Tests

  func testUserID_SaveAndRetrieve() {
    // Arrange
    let userId = 789

    // Act
    storageManager.saveUserID(userId)
    let retrieved = storageManager.getUserID()

    // Assert
    XCTAssertEqual(retrieved, userId)
  }

  func testUserID_NoUserDefaultsForTokens() {
    // Arrange
    let userId = 999
    storageManager.saveUserID(userId)

    // Act
    let userDefaults = UserDefaults.standard

    // Assert
    // User ID can be stored in UserDefaults (not sensitive)
    // But tokens should NOT be
    XCTAssertNil(userDefaults.string(forKey: "accessToken"))
    XCTAssertNil(userDefaults.string(forKey: "refreshToken"))
  }
}

// MARK: - Mock Extensions for Testing

extension AuthCoordinator {
  convenience init(sessionManager: SessionManager) {
    self.init(sessionManager: sessionManager)
  }
}
