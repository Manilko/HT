//
//  MainTabView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct MainTabView: View {
  @StateObject private var habitsCoordinator = HabitsCoordinator()

  var body: some View {
    TabView {
      HabitsView(coordinator: habitsCoordinator)
        .tabItem {
          Label("Habits", systemImage: "checkmark.circle")
        }

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
    }
  }
}

#Preview {
  MainTabView()
}
