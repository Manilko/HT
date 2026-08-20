//
//  SettingsView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct SettingsView: View {
  @StateObject private var viewModel: SettingsViewModel
  @Environment(\.dismiss) var dismiss

  init(viewModel: SettingsViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section(header: Text("Profile")) {
          Text(viewModel.userName)
          Text(viewModel.userEmail)
        }

        Section(header: Text("Preferences")) {
          Picker("Timezone", selection: $viewModel.timezone) {
            ForEach(viewModel.timezones, id: \.self) { tz in
              Text(tz).tag(tz)
            }
          }
        }

        Section {
          Button(role: .destructive, action: {
            Task {
              await viewModel.logout()
              dismiss()
            }
          }) {
            Text("Logout")
          }

          Button(role: .destructive, action: {
            Task {
              await viewModel.deleteAccount()
              dismiss()
            }
          }) {
            Text("Delete Account")
          }
        }
      }
      .navigationTitle("Settings")
    }
  }
}

#Preview {
  SettingsView(viewModel: SettingsViewModel(userService: MockUserService()))
}
