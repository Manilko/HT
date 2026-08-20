//
//  ErrorStateView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct ErrorStateView: View {
  let error: UserFacingError
  let retryAction: (() -> Void)?
  let dismissAction: (() -> Void)?

  var errorIcon: String {
    switch error {
    case .networkUnavailable, .noInternet, .networkTimeout:
      return "wifi.slash"
    case .sessionExpired, .unauthorized:
      return "lock.slash"
    case .serverError, .serviceUnavailable, .internalError:
      return "exclamationmark.triangle"
    case .validationFailed, .invalidInput:
      return "checkmark.circle.trianglebadge.exclamationmark"
    case .notFound:
      return "magnifyingglass"
    case .duplicate, .cannotModify, .cannotDelete:
      return "exclamationmark.circle"
    case .webSocketDisconnected, .webSocketAuthFailed, .webSocketError:
      return "network.slash"
    default:
      return "exclamationmark.circle.fill"
    }
  }

  var errorColor: Color {
    switch error {
    case .networkUnavailable, .noInternet, .networkTimeout, .webSocketDisconnected:
      return .orange
    case .sessionExpired, .unauthorized, .webSocketAuthFailed:
      return .red
    case .validationFailed, .invalidInput:
      return .blue
    default:
      return .red
    }
  }

  var body: some View {
    VStack(spacing: 16) {
      // Icon
      Image(systemName: errorIcon)
        .font(.system(size: 48))
        .foregroundColor(errorColor)
        .padding(.top, 20)

      // Title
      Text("Error")
        .font(.headline)
        .foregroundColor(.primary)

      // Message
      Text(error.errorDescription ?? "An unknown error occurred")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .lineLimit(5)

      // Recovery Suggestion
      if let suggestion = error.recoverySuggestion {
        Text(suggestion)
          .font(.caption)
          .foregroundColor(.secondary)
          .italic()
          .multilineTextAlignment(.center)
      }

      Spacer()

      // Buttons
      VStack(spacing: 12) {
        if let retryAction = retryAction {
          Button(action: retryAction) {
            Label("Try Again", systemImage: "arrow.clockwise")
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .background(errorColor)
              .foregroundColor(.white)
              .cornerRadius(8)
          }
        }

        if let dismissAction = dismissAction {
          Button(action: dismissAction) {
            Text("Dismiss")
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
              .foregroundColor(errorColor)
          }
        }
      }
      .padding(.bottom, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
  }
}

// MARK: - Inline Error State (for embedded screens)

struct InlineErrorView: View {
  let error: UserFacingError
  let retryAction: (() -> Void)?
  let dismissAction: (() -> Void)?

  var body: some View {
    VStack(spacing: 8) {
      HStack(spacing: 12) {
        Image(systemName: "exclamationmark.circle.fill")
          .font(.system(size: 16))
          .foregroundColor(.red)

        VStack(alignment: .leading, spacing: 4) {
          Text("Error")
            .font(.subheadline)
            .fontWeight(.semibold)

          Text(error.errorDescription ?? "An error occurred")
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        Spacer()

        Button(action: dismissAction ?? {}) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundColor(.secondary)
        }
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 12)
      .background(Color(.systemRed).opacity(0.1))
      .cornerRadius(8)

      if let retryAction = retryAction {
        Button(action: retryAction) {
          Text("Retry")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
    }
  }
}

// MARK: - Loading State with Error Fallback

struct LoadingOrErrorView<Content: View>: View {
  let isLoading: Bool
  let error: UserFacingError?
  let retryAction: (() -> Void)?
  let content: () -> Content

  var body: some View {
    if isLoading {
      VStack(spacing: 16) {
        ProgressView()
          .scaleEffect(1.2)

        Text("Loading...")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(.systemBackground))
    } else if let error = error {
      ErrorStateView(
        error: error,
        retryAction: retryAction,
        dismissAction: nil
      )
    } else {
      content()
    }
  }
}

// MARK: - Preview

#Preview {
  ErrorStateView(
    error: .alreadyCheckedInToday,
    retryAction: { print("Retry") },
    dismissAction: { print("Dismiss") }
  )
}
