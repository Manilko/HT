//
//  CheckInRepository.swift
//  HT
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import Foundation

class CheckInRepository {
  private let apiClient: CheckInsAPIClient
  private let storageManager: StorageManager
  private var checkInsCache: [Int: [CheckIn]] = [:]

  init(
    apiClient: CheckInsAPIClient = CheckInsAPIClient(),
    storageManager: StorageManager = StorageManager.shared
  ) {
    self.apiClient = apiClient
    self.storageManager = storageManager
  }

  func checkInToday(habitId: Int) async throws -> CheckIn {
    let checkIn = try await apiClient.checkInToday(habitId: habitId)
    invalidateCache(for: habitId)
    return checkIn
  }

  func getCheckIns(habitId: Int, forceRefresh: Bool = false) async throws -> [CheckIn] {
    if !forceRefresh, let cached = checkInsCache[habitId] {
      return cached
    }

    let checkIns = try await apiClient.getCheckIns(habitId: habitId)
    checkInsCache[habitId] = checkIns
    return checkIns
  }

  func undoTodaysCheckIn(habitId: Int) async throws {
    try await apiClient.undoTodaysCheckIn(habitId: habitId)
    invalidateCache(for: habitId)
  }

  func isTodayCheckedIn(habitId: Int) async throws -> Bool {
    let checkIns = try await getCheckIns(habitId: habitId)
    let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
    return checkIns.contains { $0.checkInDate.prefix(10) == today }
  }

  private func invalidateCache(for habitId: Int) {
    checkInsCache.removeValue(forKey: habitId)
  }

  func clearCache() {
    checkInsCache.removeAll()
  }
}
