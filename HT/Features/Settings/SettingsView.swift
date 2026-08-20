//
//  SettingsView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct SettingsView: View {
  @StateObject private var viewModel = SettingsViewModel()
  @EnvironmentObject var coordinator: AppCoordinator

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Profile")) {
          HStack {
            Text("User ID")
            Spacer()
            Text(viewModel.userId ?? "-")
              .foregroundColor(.gray)
          }

          HStack {
            Text("Timezone")
            Spacer()
            Picker("", selection: $viewModel.timezone) {
              ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { tz in
                Text(tz).tag(tz)
              }
            }
            .pickerStyle(.menu)
          }
        }

        Section(header: Text("Account")) {
          Button(role: .destructive, action: { Task { await logout() } }) {
            HStack {
              Image(systemName: "rectangle.portrait.and.arrow.right")
              Text("Logout")
            }
          }
          .disabled(viewModel.isLoading)

          Button(role: .destructive, action: { Task { await deleteAccount() } }) {
            HStack {
              Image(systemName: "trash")
              Text("Delete Account")
            }
          }
          .disabled(viewModel.isLoading)
        }

        if let error = viewModel.errorMessage {
          Section {
            Text(error)
              .font(.caption)
              .foregroundColor(.red)
          }
        }
      }
      .navigationTitle("Settings")
      .onAppear {
        Task {
          await viewModel.loadUserProfile()
        }
      }
    }
  }

  private func logout() async {
    await coordinator.logout()
  }

  private func deleteAccount() async {
    await viewModel.deleteAccount()
    if viewModel.errorMessage == nil {
      await coordinator.logout()
    }
  }
}

#Preview {
  SettingsView()
    .environmentObject(AppCoordinator())
}
