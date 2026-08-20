//
//  HTApp.swift
//  HT
//
//  Created by Manilko, Yevhenii on 19.08.2026.
//

import SwiftUI

@main
struct HTApp: App {
  @StateObject private var appCoordinator = AppCoordinator()
  @StateObject private var authCoordinator = AuthCoordinator()

  var body: some Scene {
    WindowGroup {
      RootView(
        appCoordinator: appCoordinator,
        authCoordinator: authCoordinator
      )
      .environmentObject(appCoordinator)
      .environmentObject(authCoordinator)
      .task {
        await authCoordinator.restoreSession()
      }
    }
  }
}
