//
//  HabitsViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class HabitsViewModel: ObservableObject {
  @Published var habits: [Habit] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let habitService: HabitService

  init(habitService: HabitService = .shared) {
    self.habitService = habitService
  }

  func loadHabits() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      self.habits = try await habitService.fetchHabits()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func createHabit(_ name: String, description: String?, color: String?) async {
    do {
      let newHabit = try await habitService.createHabit(name: name, description: description, color: color)
      self.habits.append(newHabit)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func deleteHabit(_ habitId: Int) async {
    do {
      try await habitService.deleteHabit(habitId)
      self.habits.removeAll { $0.id == habitId }
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
