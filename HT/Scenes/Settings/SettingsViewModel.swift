//
//  SettingsViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
  @Published var userName = ""
  @Published var userEmail = ""
  @Published var timezone = "UTC"
  @Published var timezones = TimeZone.knownTimeZoneIdentifiers
  @Published var isLoading = false

  private let userService: UserServiceProtocol

  init(userService: UserServiceProtocol) {
    self.userService = userService
  }

  func loadUserProfile() async {
    // Implementation coming soon
  }

  func updateTimezone(_ tz: String) async {
    // Implementation coming soon
  }

  func logout() async {
    // Implementation coming soon
  }

  func deleteAccount() async {
    // Implementation coming soon
  }
}
