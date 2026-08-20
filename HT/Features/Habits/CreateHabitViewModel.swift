//
//  CreateHabitViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class CreateHabitViewModel: ObservableObject {
  @Published var habitName = ""
  @Published var habitDescription = ""
  @Published var habitColor = Color.blue
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let habitService: HabitService

  init(habitService: HabitService = .shared) {
    self.habitService = habitService
  }

  var isFormValid: Bool {
    !habitName.trimmingCharacters(in: .whitespaces).isEmpty
  }

  func createHabit() async {
    guard isFormValid else {
      errorMessage = "Please enter a habit name"
      return
    }

    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      _ = try await habitService.createHabit(
        name: habitName,
        description: habitDescription.isEmpty ? nil : habitDescription,
        color: habitColor.toHexString()
      )
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

extension Color {
  func toHexString() -> String {
    let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
    let r = components.count > 0 ? components[0] : 0
    let g = components.count > 1 ? components[1] : 0
    let b = components.count > 2 ? components[2] : 0

    return String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
  }
}
