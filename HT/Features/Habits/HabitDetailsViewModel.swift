//
//  HabitDetailsViewModel.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation
import Combine

@MainActor
class HabitDetailsViewModel: ObservableObject {
  @Published var habit: HabitListItem?
  @Published var checkIns: [CheckIn] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var isCheckingIn = false
  @Published var checkInError: String?

  private let habitsAPIClient: HabitsAPIClient
  private let checkInRepository: CheckInRepository

  let habitId: Int

  var isEmpty: Bool {
    habit == nil && !isLoading
  }

  var hasError: Bool {
    errorMessage != nil
  }

  var todayString: String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter.string(from: Date())
  }

  init(
    habitId: Int,
    habitsAPIClient: HabitsAPIClient = HabitsAPIClient(),
    checkInRepository: CheckInRepository = CheckInRepository()
  ) {
    self.habitId = habitId
    self.habitsAPIClient = habitsAPIClient
    self.checkInRepository = checkInRepository
  }

  func loadDetails() async {
    isLoading = true
    errorMessage = nil

    do {
      let habit = try await habitsAPIClient.getHabit(id: habitId)
      let checkIns = try await checkInRepository.getCheckIns(habitId: habitId)

      self.habit = HabitListItem(
        from: habit,
        currentStreak: habit.currentStreak,
        bestStreak: habit.bestStreak,
        totalCheckIns: habit.totalCheckIns,
        todayCompleted: checkIns.contains { $0.checkInDate.prefix(10) == todayString.prefix(10) }
      )
      self.checkIns = checkIns
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  func checkInToday() async {
    guard habit?.status.isActive == true else { return }
    guard habit?.todayCompleted == false else { return }

    isCheckingIn = true
    checkInError = nil

    do {
      _ = try await habitsAPIClient.checkInToday(habitId: habitId)
      await refreshDetails()
    } catch {
      checkInError = error.localizedDescription
    }

    isCheckingIn = false
  }

  func undoTodaysCheckIn() async {
    guard habit?.status.isActive == true else { return }
    guard habit?.todayCompleted == true else { return }

    isCheckingIn = true
    checkInError = nil

    do {
      try await habitsAPIClient.undoTodaysCheckIn(habitId: habitId)
      await refreshDetails()
    } catch {
      checkInError = error.localizedDescription
    }

    isCheckingIn = false
  }

  private func refreshDetails() async {
    do {
      let habit = try await habitsAPIClient.getHabit(id: habitId)
      let checkIns = try await checkInRepository.getCheckIns(habitId: habitId, forceRefresh: true)

      self.habit = HabitListItem(
        from: habit,
        currentStreak: habit.currentStreak,
        bestStreak: habit.bestStreak,
        totalCheckIns: habit.totalCheckIns,
        todayCompleted: checkIns.contains { $0.checkInDate.prefix(10) == todayString.prefix(10) }
      )
      self.checkIns = checkIns
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func clearError() {
    errorMessage = nil
  }

  func clearCheckInError() {
    checkInError = nil
  }
}
