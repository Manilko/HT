//
//  HabitFormViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

@MainActor
class HabitFormViewModel: ObservableObject {
  @Published var name: String = ""
  @Published var description: String = ""
  @Published var startDate: Date = Date()
  @Published var errorMessage: String?
  @Published var isLoading = false

  private let habitsAPIClient: HabitsAPIClient
  private let habitToEdit: Habit?

  var isEditMode: Bool {
    habitToEdit != nil
  }

  var isFormValid: Bool {
    !name.trimmingCharacters(in: .whitespaces).isEmpty
  }

  var titleText: String {
    isEditMode ? "Edit Habit" : "Create Habit"
  }

  var submitButtonText: String {
    isEditMode ? "Update" : "Create"
  }

  init(
    habitsAPIClient: HabitsAPIClient = HabitsAPIClient(),
    habitToEdit: Habit? = nil
  ) {
    self.habitsAPIClient = habitsAPIClient
    self.habitToEdit = habitToEdit

    if let habit = habitToEdit {
      self.name = habit.name
      self.description = habit.description ?? ""

      if let date = ISO8601DateFormatter().date(from: habit.startDate) {
        self.startDate = date
      }
    } else {
      self.startDate = Date()
    }
  }

  func submit() async {
    guard isFormValid else {
      errorMessage = "Habit name is required"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      let dateString = dateFormatter.string(from: startDate)

      if isEditMode, let habit = habitToEdit {
        _ = try await habitsAPIClient.updateHabit(
          id: habit.id,
          name: name.trimmingCharacters(in: .whitespaces),
          description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
        )
      } else {
        _ = try await habitsAPIClient.createHabit(
          name: name.trimmingCharacters(in: .whitespaces),
          description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespaces),
          startDate: dateString
        )
      }

      isLoading = false
    } catch {
      errorMessage = "Failed to save habit: \(error.localizedDescription)"
      isLoading = false
    }
  }
}
