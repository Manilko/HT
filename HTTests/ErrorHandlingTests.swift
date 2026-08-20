//
//  ErrorHandlingTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

class ErrorHandlingTests: XCTestCase {
  // MARK: - User Facing Error Messages

  func testSessionExpiredError() {
    let error = UserFacingError.sessionExpired
    XCTAssertEqual(
      error.errorDescription,
      "Your session has expired. Please sign in again."
    )
    XCTAssertNotNil(error.recoverySuggestion)
    XCTAssert(error.recoverySuggestion!.contains("sign in"))
  }

  func testNetworkUnavailableError() {
    let error = UserFacingError.networkUnavailable
    XCTAssertEqual(
      error.errorDescription,
      "Network connection is unavailable. Please check your internet connection."
    )
    XCTAssert(error.recoverySuggestion!.contains("internet"))
  }

  func testValidationError() {
    let error = UserFacingError.validationFailed("Name is required")
    XCTAssert(error.errorDescription!.contains("Invalid data"))
    XCTAssert(error.errorDescription!.contains("Name is required"))
  }

  func testDuplicateCheckInError() {
    let error = UserFacingError.alreadyCheckedInToday
    XCTAssert(error.errorDescription!.contains("already completed"))
    XCTAssert(error.recoverySuggestion!.contains("once per day"))
  }

  func testCannotCheckInArched() {
    let error = UserFacingError.cannotCheckInArched
    XCTAssert(error.errorDescription!.contains("Archived"))
  }

  func testCannotCheckInPaused() {
    let error = UserFacingError.cannotCheckInPaused
    XCTAssert(error.errorDescription!.contains("Paused"))
  }

  // MARK: - HTTP Status Code Mapping

  func testMapHTTPStatusTo400Error() {
    let error = mapHTTPStatusToError(400, message: "Bad request")
    XCTAssert(error.errorDescription!.contains("Invalid"))
  }

  func testMapHTTPStatusTo401Error() {
    let error = mapHTTPStatusToError(401)
    XCTAssert(error.errorDescription!.contains("expired"))
  }

  func testMapHTTPStatusTo403Error() {
    let error = mapHTTPStatusToError(403)
    XCTAssert(error.errorDescription!.contains("not authorized"))
  }

  func testMapHTTPStatusTo404Error() {
    let error = mapHTTPStatusToError(404)
    XCTAssert(error.errorDescription!.contains("not found"))
  }

  func testMapHTTPStatusTo409Error() {
    let error = mapHTTPStatusToError(409)
    XCTAssert(error.errorDescription!.contains("already been completed"))
  }

  func testMapHTTPStatusTo500Error() {
    let error = mapHTTPStatusToError(500)
    XCTAssert(error.errorDescription!.contains("Server error"))
  }

  // MARK: - API Error Code Mapping

  func testMapAPIErrorCodeMissingToken() {
    let error = mapAPIErrorCodeToError("MISSING_TOKEN", message: "Missing")
    XCTAssert(error.errorDescription!.contains("expired"))
  }

  func testMapAPIErrorCodeDuplicateCheckIn() {
    let error = mapAPIErrorCodeToError("DUPLICATE_CHECK_IN", message: "Already checked in")
    XCTAssert(error.errorDescription!.contains("already completed"))
  }

  func testMapAPIErrorCodeNotFound() {
    let error = mapAPIErrorCodeToError("HABIT_NOT_FOUND", message: "Habit not found")
    XCTAssert(error.errorDescription!.contains("not found"))
  }

  func testMapAPIErrorCodeUnauthorized() {
    let error = mapAPIErrorCodeToError("FORBIDDEN", message: "Access denied")
    XCTAssert(error.errorDescription!.contains("not authorized"))
  }

  func testMapAPIErrorCodeArchivedHabit() {
    let error = mapAPIErrorCodeToError("ARCHIVED_HABIT_NO_CHECKIN", message: "Archived")
    XCTAssert(error.errorDescription!.contains("Archived"))
  }

  func testMapAPIErrorCodePausedHabit() {
    let error = mapAPIErrorCodeToError("PAUSED_HABIT_NO_CHECKIN", message: "Paused")
    XCTAssert(error.errorDescription!.contains("Paused"))
  }

  // MARK: - Network Error Conversion

  func testConvertNetworkErrorNotConnected() {
    let nsError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
    let error = convertNetworkError(nsError)
    XCTAssert(error.errorDescription!.contains("No internet"))
  }

  func testConvertNetworkErrorTimeout() {
    let nsError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
    let error = convertNetworkError(nsError)
    XCTAssert(error.errorDescription!.contains("timed out"))
  }

  func testConvertNetworkErrorCannotConnect() {
    let nsError = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost)
    let error = convertNetworkError(nsError)
    XCTAssert(error.errorDescription!.contains("unavailable"))
  }

  // MARK: - Error Messages Don't Expose Internals

  func testErrorMessagesAreUserFriendly() {
    let errors: [UserFacingError] = [
      .serverError,
      .internalError,
      .unknown,
      .networkUnavailable,
      .sessionExpired,
    ]

    for error in errors {
      let message = error.errorDescription ?? ""

      // Should not contain:
      // - SQL references
      // - File paths
      // - Database details
      // - Stack traces
      // - Internal codes
      XCTAssertFalse(message.contains("SELECT"), "Error exposes SQL")
      XCTAssertFalse(message.contains("INSERT"), "Error exposes SQL")
      XCTAssertFalse(message.contains("UPDATE"), "Error exposes SQL")
      XCTAssertFalse(message.contains("DELETE"), "Error exposes SQL")
      XCTAssertFalse(message.contains(".sqlite"), "Error exposes database")
      XCTAssertFalse(message.contains("Traceback"), "Error exposes stack trace")
      XCTAssertFalse(message.contains("Error:"), "Error exposes internal error")
    }
  }

  // MARK: - Error Recovery Suggestions

  func testAllErrorsHaveRecoverySuggestions() {
    let errors: [UserFacingError] = [
      .networkUnavailable,
      .sessionExpired,
      .unauthorized,
      .serverError,
      .validationFailed("test"),
      .notFound("test"),
      .duplicate("test"),
    ]

    for error in errors {
      XCTAssertNotNil(error.recoverySuggestion, "Error missing recovery suggestion: \(error)")
      XCTAssertFalse(error.recoverySuggestion!.isEmpty, "Empty recovery suggestion")
    }
  }

  // MARK: - Error Logging

  func testErrorLogging() {
    let error = UserFacingError.alreadyCheckedInToday
    // Should not crash
    logError(error, context: "Test context")
    logError(error)
  }

  // MARK: - Specific Error Scenarios

  func testValidationErrorWithCustomMessage() {
    let error = UserFacingError.validationFailed("Habit name cannot exceed 255 characters")
    XCTAssert(error.errorDescription!.contains("Invalid data"))
    XCTAssert(error.errorDescription!.contains("255 characters"))
  }

  func testInvalidInputError() {
    let error = UserFacingError.invalidInput("Start date must be in the past")
    XCTAssert(error.errorDescription!.contains("Start date must be in the past"))
  }

  func testWebSocketDisconnectedError() {
    let error = UserFacingError.webSocketDisconnected
    XCTAssert(error.errorDescription!.contains("Connection lost"))
    XCTAssert(error.recoverySuggestion!.contains("internet"))
  }

  func testWebSocketAuthFailedError() {
    let error = UserFacingError.webSocketAuthFailed
    XCTAssert(error.errorDescription!.contains("authentication failed"))
    XCTAssert(error.recoverySuggestion!.contains("sign in"))
  }

  // MARK: - Error Equality

  func testErrorEquality() {
    let error1 = UserFacingError.alreadyCheckedInToday
    let error2 = UserFacingError.alreadyCheckedInToday
    // Both should have the same error message
    XCTAssertEqual(error1.errorDescription, error2.errorDescription)
  }

  func testDifferentErrorsDifferentMessages() {
    let error1 = UserFacingError.alreadyCheckedInToday
    let error2 = UserFacingError.sessionExpired

    XCTAssertNotEqual(error1.errorDescription, error2.errorDescription)
  }
}
