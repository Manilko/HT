//
//  HabitDetailsViewModelTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

final class HabitDetailsViewModelTests: XCTestCase {
  var sut: HabitDetailsViewModel!
  var mockHabitsAPIClient: MockDetailsHabitsAPIClient!
  var mockCheckInRepository: MockCheckInRepository!

  override func setUp() {
    super.setUp()

    mockHabitsAPIClient = MockDetailsHabitsAPIClient()
    mockCheckInRepository = MockCheckInRepository()

    sut = HabitDetailsViewModel(
      habitId: 1,
      habitsAPIClient: mockHabitsAPIClient,
      checkInRepository: mockCheckInRepository
    )
  }

  override func tearDown() {
    sut = nil
    mockHabitsAPIClient = nil
    mockCheckInRepository = nil

    super.tearDown()
  }

  // MARK: - Load Details

  @MainActor
  func testLoadDetails_Success() async {
    let habit = createTestHabit(id: 1, currentStreak: 5, bestStreak: 10, totalCheckIns: 15)
    let checkIns = [
      CheckIn(id: 1, habitId: 1, userId: 1, checkInDate: "2026-08-20", createdAt: "2026-08-20T10:00:00Z"),
    ]

    mockHabitsAPIClient.getHabitResult = habit
    mockCheckInRepository.getCheckInsResult = checkIns

    await sut.loadDetails()

    XCTAssertNotNil(sut.habit)
    XCTAssertEqual(sut.habit?.id, 1)
    XCTAssertEqual(sut.habit?.currentStreak, 5)
    XCTAssertEqual(sut.habit?.bestStreak, 10)
    XCTAssertEqual(sut.habit?.totalCheckIns, 15)
    XCTAssertEqual(sut.checkIns.count, 1)
    XCTAssertNil(sut.errorMessage)
    XCTAssertFalse(sut.isLoading)
  }

  @MainActor
  func testLoadDetails_SetLoadingState() async {
    mockHabitsAPIClient.getHabitResult = createTestHabit()
    mockCheckInRepository.getCheckInsResult = []
    mockHabitsAPIClient.getHabitDelay = 0.1

    let task = Task {
      await sut.loadDetails()
    }

    try? await Task.sleep(for: .milliseconds(50))
    XCTAssertTrue(sut.isLoading)

    await task.value
    XCTAssertFalse(sut.isLoading)
  }

  @MainActor
  func testLoadDetails_Error() async {
    let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
    mockHabitsAPIClient.getHabitError = error

    await sut.loadDetails()

    XCTAssertNil(sut.habit)
    XCTAssertEqual(sut.errorMessage, "Network error")
    XCTAssertFalse(sut.isLoading)
  }

  @MainActor
  func testLoadDetails_DetectsTodayCompletion() async {
    let today = ISO8601DateFormatter().string(from: Date()).prefix(10)
    let habit = createTestHabit()
    let checkIns = [
      CheckIn(id: 1, habitId: 1, userId: 1, checkInDate: String(today), createdAt: "2026-08-20T10:00:00Z"),
    ]

    mockHabitsAPIClient.getHabitResult = habit
    mockCheckInRepository.getCheckInsResult = checkIns

    await sut.loadDetails()

    XCTAssertTrue(sut.habit?.todayCompleted ?? false)
  }

  // MARK: - Check In Today

  @MainActor
  func testCheckInToday_Success() async {
    let habit = createTestHabit(status: .active)
    let checkIn = CheckIn(
      id: 1,
      habitId: 1,
      userId: 1,
      checkInDate: "2026-08-20",
      createdAt: "2026-08-20T10:00:00Z"
    )

    sut.habit = HabitListItem(from: habit, todayCompleted: false)

    mockHabitsAPIClient.checkInTodayResult = checkIn
    mockHabitsAPIClient.getHabitResult = habit
    mockCheckInRepository.getCheckInsResult = [checkIn]

    await sut.checkInToday()

    XCTAssertEqual(mockHabitsAPIClient.checkInTodayCallCount, 1)
    XCTAssertEqual(mockHabitsAPIClient.checkInTodayHabitId, 1)
    XCTAssertNil(sut.checkInError)
  }

  @MainActor
  func testCheckInToday_IgnoreIfNotActive() async {
    let habit = createTestHabit(status: .paused)
    sut.habit = HabitListItem(from: habit, todayCompleted: false)

    await sut.checkInToday()

    XCTAssertEqual(mockHabitsAPIClient.checkInTodayCallCount, 0)
  }

  @MainActor
  func testCheckInToday_IgnoreIfAlreadyCompleted() async {
    let habit = createTestHabit(status: .active)
    sut.habit = HabitListItem(from: habit, todayCompleted: true)

    await sut.checkInToday()

    XCTAssertEqual(mockHabitsAPIClient.checkInTodayCallCount, 0)
  }

  @MainActor
  func testCheckInToday_Error() async {
    let habit = createTestHabit(status: .active)
    sut.habit = HabitListItem(from: habit, todayCompleted: false)

    let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Check-in failed"])
    mockHabitsAPIClient.checkInTodayError = error

    await sut.checkInToday()

    XCTAssertEqual(sut.checkInError, "Check-in failed")
    XCTAssertFalse(sut.isCheckingIn)
  }

  // MARK: - Undo Today's Check-in

  @MainActor
  func testUndoTodaysCheckIn_Success() async {
    let habit = createTestHabit(status: .active)
    sut.habit = HabitListItem(from: habit, todayCompleted: true)

    mockHabitsAPIClient.getHabitResult = habit
    mockCheckInRepository.getCheckInsResult = []

    await sut.undoTodaysCheckIn()

    XCTAssertEqual(mockHabitsAPIClient.undoTodaysCheckInCallCount, 1)
    XCTAssertEqual(mockHabitsAPIClient.undoTodaysCheckInHabitId, 1)
    XCTAssertNil(sut.checkInError)
  }

  @MainActor
  func testUndoTodaysCheckIn_IgnoreIfNotCompleted() async {
    let habit = createTestHabit(status: .active)
    sut.habit = HabitListItem(from: habit, todayCompleted: false)

    await sut.undoTodaysCheckIn()

    XCTAssertEqual(mockHabitsAPIClient.undoTodaysCheckInCallCount, 0)
  }

  @MainActor
  func testUndoTodaysCheckIn_Error() async {
    let habit = createTestHabit(status: .active)
    sut.habit = HabitListItem(from: habit, todayCompleted: true)

    let error = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Undo failed"])
    mockHabitsAPIClient.undoTodaysCheckInError = error

    await sut.undoTodaysCheckIn()

    XCTAssertEqual(sut.checkInError, "Undo failed")
  }

  // MARK: - Clear Error

  @MainActor
  func testClearError() {
    sut.errorMessage = "Some error"

    sut.clearError()

    XCTAssertNil(sut.errorMessage)
  }

  @MainActor
  func testClearCheckInError() {
    sut.checkInError = "Check-in error"

    sut.clearCheckInError()

    XCTAssertNil(sut.checkInError)
  }

  // MARK: - Helpers

  private func createTestHabit(
    id: Int = 1,
    status: HabitStatus = .active,
    currentStreak: Int = 5,
    bestStreak: Int = 10,
    totalCheckIns: Int = 15
  ) -> Habit {
    Habit(
      id: id,
      name: "Test Habit",
      description: "Test description",
      startDate: "2026-08-20",
      status: status,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalCheckIns: totalCheckIns,
      createdAt: "2026-08-20T10:00:00Z",
      updatedAt: "2026-08-20T10:00:00Z"
    )
  }
}

// MARK: - Mocks

class MockDetailsHabitsAPIClient: HabitsAPIClient {
  var getHabitResult: Habit?
  var getHabitError: Error?
  var getHabitCallCount = 0
  var getHabitDelay: TimeInterval = 0

  var checkInTodayResult: CheckIn?
  var checkInTodayError: Error?
  var checkInTodayCallCount = 0
  var checkInTodayHabitId: Int?

  var undoTodaysCheckInError: Error?
  var undoTodaysCheckInCallCount = 0
  var undoTodaysCheckInHabitId: Int?

  override func getHabit(id: Int) async throws -> Habit {
    if getHabitDelay > 0 {
      try? await Task.sleep(for: .seconds(getHabitDelay))
    }

    getHabitCallCount += 1

    if let error = getHabitError {
      throw error
    }

    guard let result = getHabitResult else {
      throw NSError(domain: "mock", code: 1)
    }

    return result
  }

  override func checkInToday(habitId: Int) async throws -> CheckIn {
    checkInTodayCallCount += 1
    checkInTodayHabitId = habitId

    if let error = checkInTodayError {
      throw error
    }

    guard let result = checkInTodayResult else {
      throw NSError(domain: "mock", code: 1)
    }

    return result
  }

  override func undoTodaysCheckIn(habitId: Int) async throws {
    undoTodaysCheckInCallCount += 1
    undoTodaysCheckInHabitId = habitId

    if let error = undoTodaysCheckInError {
      throw error
    }
  }
}
