//
//  HabitDetailViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class HabitDetailViewModel: ObservableObject {
  let habitId: Int

  @Published var habit: Habit?
  @Published var streak: Streak?
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let habitService: HabitService

  init(habitId: Int, habitService: HabitService = .shared) {
    self.habitId = habitId
    self.habitService = habitService
  }

  func loadHabitDetails() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      self.habit = try await habitService.fetchHabit(habitId)
      self.streak = try await habitService.fetchStreak(habitId)
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func logCheckIn() async {
    isLoading = true
    defer { isLoading = false }

    do {
      _ = try await habitService.logCheckIn(habitId: habitId, notes: nil)
      await loadHabitDetails()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
