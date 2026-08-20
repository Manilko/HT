//
//  MainTabView.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI

struct MainTabView: View {
  var body: some View {
    TabView {
      HabitListView()
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
