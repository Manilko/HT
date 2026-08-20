//
//  HabitListViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Combine

@MainActor
class HabitListViewModel: ObservableObject {
  @Published var habits: [HabitListItem] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var showDeleteConfirmation = false
  @Published var habitToDelete: HabitListItem?

  private let habitsAPIClient: HabitsAPIClient

  var isEmpty: Bool {
    habits.isEmpty && !isLoading
  }

  var hasError: Bool {
    errorMessage != nil
  }

  init(habitsAPIClient: HabitsAPIClient = HabitsAPIClient()) {
    self.habitsAPIClient = habitsAPIClient
  }

  func loadHabits() async {
    isLoading = true
    errorMessage = nil

    do {
      let fetchedHabits = try await habitsAPIClient.listHabits()
      self.habits = fetchedHabits.map { habit in
        HabitListItem(from: habit)
      }
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func archiveHabit(_ habit: HabitListItem) async {
    do {
      _ = try await habitsAPIClient.archiveHabit(id: habit.id)
      await loadHabits()
    } catch {
      errorMessage = "Failed to archive habit: \(error.localizedDescription)"
    }
  }

  func pauseHabit(_ habit: HabitListItem) async {
    do {
      _ = try await habitsAPIClient.pauseHabit(id: habit.id)
      await loadHabits()
    } catch {
      errorMessage = "Failed to pause habit: \(error.localizedDescription)"
    }
  }

  func resumeHabit(_ habit: HabitListItem) async {
    do {
      _ = try await habitsAPIClient.resumeHabit(id: habit.id)
      await loadHabits()
    } catch {
      errorMessage = "Failed to resume habit: \(error.localizedDescription)"
    }
  }

  func deleteHabit(_ habit: HabitListItem) async {
    do {
      try await habitsAPIClient.deleteHabit(id: habit.id)
      await loadHabits()
    } catch {
      errorMessage = "Failed to delete habit: \(error.localizedDescription)"
    }
  }

  func confirmDeleteHabit(_ habit: HabitListItem) {
    habitToDelete = habit
    showDeleteConfirmation = true
  }

  func clearError() {
    errorMessage = nil
  }
}
