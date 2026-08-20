//
//  HTApp.swift
//  HT
//
//  Created by Manilko, Yevhenii on 19.08.2026.
//

import SwiftUI

@main
struct HTApp: App {
  @StateObject private var coordinator = AppCoordinator()
  @StateObject private var sessionManager = SessionManager.shared

  var body: some Scene {
    WindowGroup {
      RootView(coordinator: coordinator)
        .environmentObject(coordinator)
        .environmentObject(sessionManager)
        .task {
          await sessionManager.initializeSession()
        }
    }
  }
}
