//
//  SettingsViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine
import Security

@MainActor
class SettingsViewModel: ObservableObject {
  @Published var userId: String?
  @Published var timezone: String = TimeZone.current.identifier
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let userService: UserService
  private let storageManager: StorageManager

  init(userService: UserService = .shared, storageManager: StorageManager = .shared) {
    self.userService = userService
    self.storageManager = storageManager
    self.timezone = storageManager.getTimezone()
  }

  func loadUserProfile() async {
    isLoading = true
    defer { isLoading = false }

    if let uid = storageManager.getUserID() {
      self.userId = String(uid)
    }
  }

  func updateTimezone() async {
    storageManager.saveTimezone(timezone)
  }

  func deleteAccount() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      try await userService.deleteAccount()
      storageManager.clearAllTokens()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
