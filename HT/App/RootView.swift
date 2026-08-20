//
//  RootView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct RootView: View {
  @StateObject private var appCoordinator: AppCoordinator
  @StateObject private var authCoordinator: AuthCoordinator

  init(appCoordinator: AppCoordinator, authCoordinator: AuthCoordinator) {
    _appCoordinator = StateObject(wrappedValue: appCoordinator)
    _authCoordinator = StateObject(wrappedValue: authCoordinator)
  }

  var body: some View {
    Group {
      if authCoordinator.isRestoring {
        // Show splash screen while restoring session
        ZStack {
          Color(.systemBackground)
            .ignoresSafeArea()

          VStack(spacing: 20) {
            Text("Habit Tracker")
              .font(.system(size: 34, weight: .bold))

            ProgressView()
              .padding()
          }
        }
      } else if authCoordinator.isAuthenticated {
        NavigationStack(path: $appCoordinator.path) {
          MainTabView()
            .navigationDestination(for: AppCoordinator.Route.self) { route in
              appCoordinator.view(for: route)
            }
        }
        .environmentObject(appCoordinator)
      } else {
        AuthenticationView()
      }
    }
  }
}

#Preview {
  let appCoordinator = AppCoordinator()
  let authCoordinator = AuthCoordinator()
  RootView(appCoordinator: appCoordinator, authCoordinator: authCoordinator)
    .environmentObject(appCoordinator)
    .environmentObject(authCoordinator)
}
