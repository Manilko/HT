//
//  LoginView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct LoginView: View {
  @StateObject private var viewModel = AuthViewModel()
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    ZStack {
      // Background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(.systemBackground),
          Color(.systemBackground).opacity(0.8),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        // Header
        VStack(spacing: 12) {
          Text("Habit Tracker")
            .font(.system(size: 34, weight: .bold))
            .tracking(-0.5)

          Text("Build better habits, one day at a time")
            .font(.subheadline)
            .foregroundColor(.gray)
        }
        .padding(.top, 60)
        .padding(.bottom, 80)

        Spacer()

        // Authentication Buttons
        VStack(spacing: 12) {
          // Google Button
          SignInButton(
            icon: "g.circle.fill",
            title: "Continue with Google",
            backgroundColor: Color.blue,
            action: {
              Task { await viewModel.signInWithGoogle() }
            },
            isLoading: viewModel.authState == .authenticating,
            isDisabled: !viewModel.isSignInEnabled
          )
          .accessibilityLabel("Sign in with Google")
          .accessibilityHint("Opens Safari to authenticate with your Google account")

          // GitHub Button
          SignInButton(
            icon: "github",
            title: "Continue with GitHub",
            backgroundColor: Color.black,
            action: {
              Task { await viewModel.signInWithGitHub() }
            },
            isLoading: viewModel.authState == .authenticating,
            isDisabled: !viewModel.isSignInEnabled
          )
          .accessibilityLabel("Sign in with GitHub")
          .accessibilityHint("Opens Safari to authenticate with your GitHub account")
        }
        .padding(.horizontal, 20)

        Spacer()

        // Error Message
        if let errorMessage = viewModel.errorMessage {
          VStack(spacing: 12) {
            HStack(spacing: 12) {
              Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)

              VStack(alignment: .leading, spacing: 4) {
                Text("Authentication Failed")
                  .font(.subheadline)
                  .fontWeight(.semibold)

                Text(errorMessage)
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .lineLimit(3)
              }

              Spacer()
            }
            .padding(12)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)

            Button(action: viewModel.clearError) {
              Text("Dismiss")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }

        Spacer()
          .frame(height: 40)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: viewModel.authState)
    .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
  }
}

// MARK: - Sign In Button Component

struct SignInButton: View {
  let icon: String
  let title: String
  let backgroundColor: Color
  let action: () -> Void
  let isLoading: Bool
  let isDisabled: Bool

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        if isLoading {
          ProgressView()
            .tint(.white)
            .scaleEffect(0.9)
        } else {
          Image(systemName: icon)
            .font(.system(size: 20))
        }

        Text(title)
          .font(.system(size: 16, weight: .semibold))

        Spacer()
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .padding(.horizontal, 20)
      .foregroundColor(.white)
      .background(backgroundColor)
      .cornerRadius(10)
      .opacity(isDisabled ? 0.6 : 1.0)
    }
    .disabled(isDisabled)
  }
}

// MARK: - Preview

#Preview {
  LoginView()
}
