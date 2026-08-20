//
//  APIErrorHandling.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

// MARK: - API Error Types

enum APIErrorType: String {
  case networkUnavailable = "Network Unavailable"
  case serverError = "Server Error"
  case unauthorized = "Unauthorized"
  case sessionExpired = "Session Expired"
  case validationError = "Validation Error"
  case notFound = "Not Found"
  case duplicate = "Already Done"
  case unknown = "Something Went Wrong"
}

// MARK: - User-Friendly Error Messages

enum UserFacingError: LocalizedError {
  // Network Errors
  case networkUnavailable
  case networkTimeout
  case noInternet

  // Authentication Errors
  case sessionExpired
  case unauthorized
  case invalidCredentials
  case authenticationFailed(String)

  // Server Errors
  case serverError
  case serviceUnavailable
  case internalError

  // Validation Errors
  case validationFailed(String)
  case invalidInput(String)

  // Resource Errors
  case notFound(String)
  case duplicate(String)
  case cannotDelete(String)
  case cannotModify(String)

  // Habit-Specific Errors
  case cannotCheckInArched
  case cannotCheckInPaused
  case alreadyCheckedInToday
  case cannotUndoCheckIn(String)

  // WebSocket Errors
  case webSocketDisconnected
  case webSocketAuthFailed
  case webSocketError(String)

  // Other Errors
  case unknown

  var errorDescription: String? {
    switch self {
    // Network
    case .networkUnavailable:
      return "Network connection is unavailable. Please check your internet connection."
    case .networkTimeout:
      return "Request timed out. Please try again."
    case .noInternet:
      return "No internet connection. Please check your network."

    // Authentication
    case .sessionExpired:
      return "Your session has expired. Please sign in again."
    case .unauthorized:
      return "You are not authorized to access this resource."
    case .invalidCredentials:
      return "Your credentials are invalid. Please try again."
    case .authenticationFailed(let message):
      return "Authentication failed: \(message)"

    // Server
    case .serverError:
      return "Server error. Please try again later."
    case .serviceUnavailable:
      return "The service is currently unavailable. Please try again later."
    case .internalError:
      return "Something went wrong on our end. Please try again later."

    // Validation
    case .validationFailed(let message):
      return "Invalid data: \(message)"
    case .invalidInput(let message):
      return "\(message)"

    // Resources
    case .notFound(let resource):
      return "\(resource) not found."
    case .duplicate(let message):
      return message
    case .cannotDelete(let resource):
      return "Cannot delete \(resource)."
    case .cannotModify(let resource):
      return "Cannot modify \(resource)."

    // Habits
    case .cannotCheckInArched:
      return "Archived habits cannot be checked in."
    case .cannotCheckInPaused:
      return "Paused habits cannot be checked in."
    case .alreadyCheckedInToday:
      return "You have already completed this habit today."
    case .cannotUndoCheckIn(let message):
      return message

    // WebSocket
    case .webSocketDisconnected:
      return "Connection lost. Please check your internet."
    case .webSocketAuthFailed:
      return "Connection authentication failed. Please sign in again."
    case .webSocketError(let message):
      return "Connection error: \(message)"

    // Other
    case .unknown:
      return "An unexpected error occurred. Please try again."
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .networkUnavailable, .noInternet, .networkTimeout:
      return "Check your internet connection and try again."

    case .sessionExpired:
      return "Please sign in again to continue."

    case .unauthorized:
      return "You may need to sign in again or check your permissions."

    case .serverError, .serviceUnavailable, .internalError:
      return "Please try again in a few moments."

    case .validationFailed, .invalidInput:
      return "Please check your input and try again."

    case .notFound:
      return "This item may have been deleted. Please refresh."

    case .duplicate:
      return "This action has already been completed."

    case .cannotCheckInArched, .cannotCheckInPaused:
      return "Check the habit status and try again."

    case .alreadyCheckedInToday:
      return "You can only check in once per day."

    case .webSocketDisconnected, .webSocketAuthFailed, .webSocketError:
      return "Try refreshing the screen or signing in again."

    case .unknown:
      return "If the problem persists, try restarting the app."

    default:
      return nil
    }
  }
}

// MARK: - HTTP Status Code Mapping

func mapHTTPStatusToError(_ statusCode: Int, message: String? = nil) -> UserFacingError {
  switch statusCode {
  case 400:
    return .validationFailed(message ?? "Invalid request")

  case 401:
    return .sessionExpired

  case 403:
    return .unauthorized

  case 404:
    return .notFound(message ?? "Resource")

  case 409:
    return .duplicate(message ?? "This action has already been completed.")

  case 500...599:
    return .serverError

  default:
    return .unknown
  }
}

// MARK: - API Error Code Mapping

func mapAPIErrorCodeToError(_ code: String, message: String) -> UserFacingError {
  switch code {
  case "MISSING_TOKEN", "INVALID_TOKEN", "EXPIRED_TOKEN", "MALFORMED_TOKEN":
    return .sessionExpired

  case "FORBIDDEN", "HABIT_NOT_OWNED", "CHECK_IN_NOT_OWNED":
    return .unauthorized

  case "INVALID_REQUEST":
    if message.lowercased().contains("empty") || message.lowercased().contains("required") {
      return .invalidInput(message)
    }
    return .validationFailed(message)

  case "INVALID_HABIT_NAME":
    return .invalidInput("Habit name is required")

  case "INVALID_START_DATE":
    return .invalidInput("Start date cannot be in the future")

  case "INVALID_STATUS_TRANSITION":
    return .validationFailed("This status change is not allowed")

  case "ARCHIVED_HABIT_READ_ONLY", "ARCHIVED_HABIT_NO_CHECKIN":
    return .cannotCheckInArched

  case "PAUSED_HABIT_NO_CHECKIN":
    return .cannotCheckInPaused

  case "DUPLICATE_CHECK_IN":
    return .alreadyCheckedInToday

  case "NOT_FOUND", "HABIT_NOT_FOUND":
    return .notFound("Habit")

  case "CHECK_IN_NOT_FOUND":
    return .notFound("Check-in")

  case "USER_NOT_FOUND":
    return .notFound("User")

  case "INVALID_AUTH_CODE", "OAUTH_EXCHANGE_FAILED", "OAUTH_USER_INFO_FAILED":
    return .authenticationFailed(message)

  case "INTERNAL_ERROR":
    return .internalError

  case "UNAUTHORIZED":
    return .sessionExpired

  default:
    return .unknown
  }
}

// MARK: - Network Error Conversion

func convertNetworkError(_ error: Error) -> UserFacingError {
  let nsError = error as NSError

  // Check for network-related error codes
  if nsError.domain == NSURLErrorDomain {
    switch nsError.code {
    case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
      return .noInternet

    case NSURLErrorTimedOut:
      return .networkTimeout

    case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
      return .networkUnavailable

    default:
      return .networkUnavailable
    }
  }

  return .networkUnavailable
}

// MARK: - Error Logging

func logError(_ error: UserFacingError, context: String = "") {
  let message = error.errorDescription ?? "Unknown error"
  let suggestion = error.recoverySuggestion ?? "No suggestion available"

  var logMessage = "API Error: \(message)"
  if !context.isEmpty {
    logMessage += " (Context: \(context))"
  }
  logMessage += "\nSuggestion: \(suggestion)"

  print(logMessage)
}
