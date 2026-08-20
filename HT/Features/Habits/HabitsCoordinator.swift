//
//  HabitsCoordinator.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class HabitsCoordinator: ObservableObject {
  @Published var path: [HabitRoute] = []

  enum HabitRoute: Hashable {
    case detail(habitId: Int)
    case create
  }

  @ViewBuilder
  func view(for route: HabitRoute) -> some View {
    switch route {
    case .detail(let habitId):
      HabitDetailView(habitId: habitId)

    case .create:
      CreateHabitView()
    }
  }

  func navigate(to route: HabitRoute) {
    path.append(route)
  }

  func navigateBack() {
    if !path.isEmpty {
      path.removeLast()
    }
  }
}
