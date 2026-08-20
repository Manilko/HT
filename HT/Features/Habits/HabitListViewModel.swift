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
  @Published var allHabits: [HabitListItem] = []
  @Published var filteredHabits: [HabitListItem] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var showDeleteConfirmation = false
  @Published var habitToDelete: HabitListItem?

  // Search and filtering
  @Published var searchText: String = ""
  @Published var selectedStatuses: Set<HabitStatus> = [.active, .paused, .archived]
  @Published var showCompletedOnly: Bool = false

  // Check-in state
  @Published var checkingInHabitId: Int?
  @Published var checkInErrors: [Int: String] = [:]

  private let habitsAPIClient: HabitsAPIClient
  private let checkInsAPIClient: CheckInsAPIClient
  private let checkInRepository: CheckInRepository

  var isEmpty: Bool {
    filteredHabits.isEmpty && !isLoading
  }

  var hasError: Bool {
    errorMessage != nil
  }

  var hasActiveFilters: Bool {
    !searchText.isEmpty || selectedStatuses.count < 3 || showCompletedOnly
  }

  init(
    habitsAPIClient: HabitsAPIClient = HabitsAPIClient(),
    checkInsAPIClient: CheckInsAPIClient = CheckInsAPIClient(),
    checkInRepository: CheckInRepository = CheckInRepository()
  ) {
    self.habitsAPIClient = habitsAPIClient
    self.checkInsAPIClient = checkInsAPIClient
    self.checkInRepository = checkInRepository
  }

  func loadHabits() async {
    isLoading = true
    errorMessage = nil

    do {
      let fetchedHabits = try await habitsAPIClient.listHabits()

      var habitItems: [HabitListItem] = []
      for habit in fetchedHabits {
        let checkIns = try await checkInRepository.getCheckIns(habitId: habit.id)
        let todayCheckedIn = checkIns.contains { checkIn in
          let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
          return checkIn.checkInDate.prefix(10) == today
        }

        let item = HabitListItem(
          from: habit,
          currentStreak: habit.currentStreak,
          bestStreak: habit.bestStreak,
          totalCheckIns: habit.totalCheckIns,
          todayCompleted: todayCheckedIn && habit.status.isActive
        )
        habitItems.append(item)
      }

      self.allHabits = habitItems
      applyFilters()
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }


  private func applyFilters() {
    var filtered = allHabits

    // Apply status filter
    filtered = filtered.filter { selectedStatuses.contains($0.status) }

    // Apply search filter (name and description)
    if !searchText.isEmpty {
      let searchLower = searchText.lowercased()
      filtered = filtered.filter { habit in
        habit.name.lowercased().contains(searchLower) ||
          (habit.description?.lowercased().contains(searchLower) ?? false)
      }
    }

    // Apply completion filter (only for active habits)
    if showCompletedOnly {
      filtered = filtered.filter { $0.status.isActive && $0.todayCompleted }
    }

    self.filteredHabits = filtered
  }

  func updateSearch(_ text: String) {
    searchText = text
    applyFilters()
  }

  func toggleStatus(_ status: HabitStatus) {
    if selectedStatuses.contains(status) {
      selectedStatuses.remove(status)
    } else {
      selectedStatuses.insert(status)
    }
    applyFilters()
  }

  func toggleCompletionFilter() {
    showCompletedOnly.toggle()
    applyFilters()
  }

  func clearFilters() {
    searchText = ""
    selectedStatuses = [.active, .paused, .archived]
    showCompletedOnly = false
    applyFilters()
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

  func checkInToday(_ habit: HabitListItem) async {
    guard checkingInHabitId == nil else { return }
    guard !habit.todayCompleted else { return }
    guard habit.status.isActive else { return }

    checkingInHabitId = habit.id
    checkInErrors.removeValue(forKey: habit.id)

    do {
      _ = try await checkInsAPIClient.checkInToday(habitId: habit.id)
      await refreshHabitAfterCheckIn(habit.id)
    } catch {
      checkInErrors[habit.id] = error.localizedDescription
    }

    checkingInHabitId = nil
  }

  func undoTodaysCheckIn(_ habit: HabitListItem) async {
    guard checkingInHabitId == nil else { return }
    guard habit.todayCompleted else { return }
    guard habit.status.isActive else { return }

    checkingInHabitId = habit.id
    checkInErrors.removeValue(forKey: habit.id)

    do {
      try await checkInsAPIClient.undoTodaysCheckIn(habitId: habit.id)
      await refreshHabitAfterCheckIn(habit.id)
    } catch {
      checkInErrors[habit.id] = error.localizedDescription
    }

    checkingInHabitId = nil
  }

  private func refreshHabitAfterCheckIn(_ habitId: Int) async {
    do {
      let habit = try await habitsAPIClient.getHabit(id: habitId)
      let checkIns = try await checkInRepository.getCheckIns(habitId: habitId, forceRefresh: true)

      let todayCheckedIn = checkIns.contains { checkIn in
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
        return checkIn.checkInDate.prefix(10) == today
      }

      let updatedItem = HabitListItem(
        from: habit,
        currentStreak: habit.currentStreak,
        bestStreak: habit.bestStreak,
        totalCheckIns: habit.totalCheckIns,
        todayCompleted: todayCheckedIn && habit.status.isActive
      )

      if let index = allHabits.firstIndex(where: { $0.id == habitId }) {
        allHabits[index] = updatedItem
        applyFilters()
      }
    } catch {
      checkInErrors[habitId] = "Failed to refresh habit: \(error.localizedDescription)"
    }
  }

  func clearCheckInError(_ habitId: Int) {
    checkInErrors.removeValue(forKey: habitId)
  }

  func clearError() {
    errorMessage = nil
  }
}
