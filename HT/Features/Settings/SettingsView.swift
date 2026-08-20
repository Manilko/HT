//
//  SettingsView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.scenePhase) var scenePhase
  @StateObject private var logoutService = LogoutService()
  @State private var isLoggingOut = false
  @State private var showLogoutConfirmation = false
  @State private var logoutError: String?

  var body: some View {
    NavigationStack {
      List {
        Section("App") {
          HStack {
            Text("Version")
            Spacer()
            Text("1.0.0")
              .foregroundColor(.secondary)
          }
        }

        Section("About") {
          Text("Track your daily habits and celebrate your streaks.")
            .foregroundColor(.secondary)
            .font(.subheadline)
        }

        Section("Account") {
          Button(role: .destructive, action: { showLogoutConfirmation = true }) {
            HStack {
              Image(systemName: "rectangle.portrait.and.arrow.right")
              Text("Logout")
            }
          }
          .disabled(isLoggingOut)
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.inline)
    }
    .alert("Logout?", isPresented: $showLogoutConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Logout", role: .destructive) {
        Task {
          await performLogout()
        }
      }
    } message: {
      Text("You will be logged out and returned to the login screen.")
    }
    .alert("Logout Error", isPresented: .constant(logoutError != nil)) {
      Button("OK") {
        logoutError = nil
      }
    } message: {
      if let error = logoutError {
        Text(error)
      }
    }
  }

  private func performLogout() async {
    isLoggingOut = true

    do {
      try await logoutService.logout()
      // Navigation handled by AppState or root view observation
      print("✓ Logout successful")
    } catch {
      logoutError = "Failed to logout: \(error.localizedDescription)"
      print("✗ Logout failed: \(error.localizedDescription)")
    }

    isLoggingOut = false
  }
}

#Preview {
  SettingsView()
}
