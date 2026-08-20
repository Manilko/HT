//
//  AppCoordinator.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

enum AppRoute: Hashable {
  case auth
  case habits
  case settings
}

@MainActor
class AppCoordinator: ObservableObject {
  @Published var path: [AppRoute] = []
  @Published var isAuthenticated = false

  func navigate(to route: AppRoute) {
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

  func logOut() {
    isAuthenticated = false
    path.removeAll()
  }
}
