//
//  HabitsListViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class HabitsListViewModel: ObservableObject {
  @Published var habits: [Habit] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let habitService: HabitServiceProtocol

  init(habitService: HabitServiceProtocol) {
    self.habitService = habitService
  }

  func loadHabits() async {
    // Implementation coming soon
  }

  func searchHabits(query: String) async {
    // Implementation coming soon
  }

  func deleteHabit(_ habit: Habit) async {
    // Implementation coming soon
  }
}
