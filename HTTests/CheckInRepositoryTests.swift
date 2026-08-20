//
//  CheckInRepositoryTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

final class CheckInRepositoryTests: XCTestCase {
  var sut: CheckInRepository!
  var mockAPIClient: MockCheckInsAPIClient!
  var mockStorageManager: MockStorageManager!

  override func setUp() {
    super.setUp()

    mockAPIClient = MockCheckInsAPIClient()
    mockStorageManager = MockStorageManager()

    sut = CheckInRepository(
      apiClient: mockAPIClient,
      storageManager: mockStorageManager
    )
  }

  override func tearDown() {
    sut = nil
    mockAPIClient = nil
    mockStorageManager = nil

    super.tearDown()
  }

  // MARK: - Check In Today

  func testCheckInToday() async throws {
    let habitId = 1
    let checkIn = CheckIn(
      id: 1,
      habitId: habitId,
      userId: 1,
      checkInDate: "2026-08-20",
      createdAt: "2026-08-20T10:00:00Z"
    )

    mockAPIClient.checkInToTodayResult = checkIn

    let result = try await sut.checkInToday(habitId: habitId)

    XCTAssertEqual(result.id, checkIn.id)
    XCTAssertEqual(result.habitId, habitId)
  }

  // MARK: - Get Check-ins

  func testGetCheckIns_ReturnsCached() async throws {
    let habitId = 1
    let checkIns = [
      CheckIn(
        id: 1,
        habitId: habitId,
        userId: 1,
        checkInDate: "2026-08-20",
        createdAt: "2026-08-20T10:00:00Z"
      ),
    ]

    mockAPIClient.getCheckInsResult = checkIns
    var callCount = 0
    mockAPIClient.getCheckInsOnCall = { callCount += 1 }

    let result1 = try await sut.getCheckIns(habitId: habitId, forceRefresh: false)
    let result2 = try await sut.getCheckIns(habitId: habitId, forceRefresh: false)

    XCTAssertEqual(callCount, 1)
    XCTAssertEqual(result1.count, 1)
    XCTAssertEqual(result2.count, 1)
  }

  func testGetCheckIns_ForceRefresh() async throws {
    let habitId = 1
    let checkIns = [
      CheckIn(
        id: 1,
        habitId: habitId,
        userId: 1,
        checkInDate: "2026-08-20",
        createdAt: "2026-08-20T10:00:00Z"
      ),
    ]

    mockAPIClient.getCheckInsResult = checkIns
    var callCount = 0
    mockAPIClient.getCheckInsOnCall = { callCount += 1 }

    _ = try await sut.getCheckIns(habitId: habitId, forceRefresh: false)
    _ = try await sut.getCheckIns(habitId: habitId, forceRefresh: true)

    XCTAssertEqual(callCount, 2)
  }

  // MARK: - Undo Today's Check-in

  func testUndoTodaysCheckIn() async throws {
    let habitId = 1

    try await sut.undoTodaysCheckIn(habitId: habitId)

    XCTAssertEqual(mockAPIClient.undoTodaysCheckInCallCount, 1)
    XCTAssertEqual(mockAPIClient.lastUndoHabitId, habitId)
  }

  func testUndoTodaysCheckIn_InvaliatesCach() async throws {
    let habitId = 1
    let checkIns = [
      CheckIn(
        id: 1,
        habitId: habitId,
        userId: 1,
        checkInDate: "2026-08-20",
        createdAt: "2026-08-20T10:00:00Z"
      ),
    ]

    mockAPIClient.getCheckInsResult = checkIns

    _ = try await sut.getCheckIns(habitId: habitId)
    try await sut.undoTodaysCheckIn(habitId: habitId)

    mockAPIClient.getCheckInsResult = []

    let result = try await sut.getCheckIns(habitId: habitId, forceRefresh: false)

    XCTAssertEqual(result.count, 0)
  }

  // MARK: - Is Today Checked In

  func testIsTodayCheckedIn_True() async throws {
    let habitId = 1
    let today = ISO8601DateFormatter().string(from: Date()).prefix(10)

    mockAPIClient.getCheckInsResult = [
      CheckIn(
        id: 1,
        habitId: habitId,
        userId: 1,
        checkInDate: String(today),
        createdAt: "2026-08-20T10:00:00Z"
      ),
    ]

    let result = try await sut.isTodayCheckedIn(habitId: habitId)

    XCTAssertTrue(result)
  }

  func testIsTodayCheckedIn_False() async throws {
    let habitId = 1

    mockAPIClient.getCheckInsResult = [
      CheckIn(
        id: 1,
        habitId: habitId,
        userId: 1,
        checkInDate: "2026-08-19",
        createdAt: "2026-08-19T10:00:00Z"
      ),
    ]

    let result = try await sut.isTodayCheckedIn(habitId: habitId)

    XCTAssertFalse(result)
  }

  // MARK: - Clear Cache

  func testClearCache() async throws {
    let habitId = 1
    let checkIns = [
      CheckIn(
        id: 1,
        habitId: habitId,
        userId: 1,
        checkInDate: "2026-08-20",
        createdAt: "2026-08-20T10:00:00Z"
      ),
    ]

    mockAPIClient.getCheckInsResult = checkIns

    _ = try await sut.getCheckIns(habitId: habitId)
    sut.clearCache()

    mockAPIClient.getCheckInsResult = []
    var callCount = 0
    mockAPIClient.getCheckInsOnCall = { callCount += 1 }

    let result = try await sut.getCheckIns(habitId: habitId, forceRefresh: false)

    XCTAssertEqual(callCount, 1)
    XCTAssertEqual(result.count, 0)
  }
}

class MockStorageManager: StorageManager {
  override init() {
    super.init()
  }
}
