//
//  RootView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct RootView: View {
  @StateObject private var coordinator: AppCoordinator

  init(coordinator: AppCoordinator) {
    _coordinator = StateObject(wrappedValue: coordinator)
  }

  var body: some View {
    NavigationStack(path: $coordinator.path) {
      Group {
        if coordinator.isAuthenticated {
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
  }
}

#Preview {
  let coordinator = AppCoordinator()
  RootView(coordinator: coordinator)
}
