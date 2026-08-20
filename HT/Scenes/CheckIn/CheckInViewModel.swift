//
//  CheckInViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import SwiftUI
import Combine

@MainActor
class CheckInViewModel: ObservableObject {
  @Published var notes = ""
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let habitService: HabitServiceProtocol

  init(habitService: HabitServiceProtocol) {
    self.habitService = habitService
  }

  func logCheckIn(habitId: Int) async {
    // Implementation coming soon
  }

  func deleteCheckIn(habitId: Int, date: String) async {
    // Implementation coming soon
  }
}
