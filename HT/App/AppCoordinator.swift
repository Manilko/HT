//
//  AppCoordinator.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class AppCoordinator: ObservableObject {
  enum Route: Hashable {
    case habitDetail(habitId: Int)
    case settings
  }

  @Published var path: [Route] = []
  @Published var isAuthenticated = false
  @Published var authenticationError: String?

  private let authManager: AuthenticationManager

  init(authManager: AuthenticationManager = AuthenticationManager.shared) {
    self.authManager = authManager
    self.isAuthenticated = authManager.isAuthenticated()
  }

  @ViewBuilder
  func view(for route: Route) -> some View {
    switch route {
    case .habitDetail(let habitId):
      HabitDetailView(habitId: habitId)

    case .settings:
      SettingsView()
    }
  }

  func navigate(to route: Route) {
    path.append(route)
  }

  func navigateBack() {
    if !path.isEmpty {
      path.removeLast()
    }
  }

  func navigateToRoot() {
    path.removeAll()
  }

  func logout() async {
    do {
      try await authManager.logout()
      await MainActor.run {
        self.isAuthenticated = false
        self.path.removeAll()
      }
    } catch {
      await MainActor.run {
        self.authenticationError = error.localizedDescription
      }
    }
  }

  func setAuthenticated(_ authenticated: Bool) {
    isAuthenticated = authenticated
  }
}
