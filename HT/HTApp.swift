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

  var body: some Scene {
    WindowGroup {
      RootView(coordinator: coordinator)
        .environmentObject(coordinator)
    }
  }
}
