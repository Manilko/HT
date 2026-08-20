//
//  RootView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct RootView: View {
  @StateObject private var coordinator: AppCoordinator
  @EnvironmentObject var sessionManager: SessionManager

  init(coordinator: AppCoordinator) {
    _coordinator = StateObject(wrappedValue: coordinator)
  }

  var body: some View {
    NavigationStack(path: $coordinator.path) {
      Group {
        if sessionManager.isAuthenticated {
          MainTabView()
        } else {
          AuthenticationView()
        }
      }
      .navigationDestination(for: AppCoordinator.Route.self) { route in
        coordinator.view(for: route)
      }
    }
    .environmentObject(coordinator)
    .onChange(of: sessionManager.isAuthenticated) { _, newValue in
      coordinator.setAuthenticated(newValue)
    }
  }
}

#Preview {
  let coordinator = AppCoordinator()
  let sessionManager = SessionManager.shared
  RootView(coordinator: coordinator)
    .environmentObject(sessionManager)
}
