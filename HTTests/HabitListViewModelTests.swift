//
//  HabitListViewModelTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

final class HabitListViewModelTests: XCTestCase {
  var sut: HabitListViewModel!
  var mockHabitsAPIClient: MockHabitsAPIClient!
  var mockCheckInsAPIClient: MockCheckInsAPIClient!
  var mockCheckInRepository: MockCheckInRepository!

  override func setUp() {
    super.setUp()

    mockHabitsAPIClient = MockHabitsAPIClient()
    mockCheckInsAPIClient = MockCheckInsAPIClient()
    mockCheckInRepository = MockCheckInRepository()

    sut = HabitListViewModel(
      habitsAPIClient: mockHabitsAPIClient,
      checkInsAPIClient: mockCheckInsAPIClient,
      checkInRepository: mockCheckInRepository
    )
  }

  override func tearDown() {
    sut = nil
    mockHabitsAPIClient = nil
    mockCheckInsAPIClient = nil
    mockCheckInRepository = nil

    super.tearDown()
  }

  // MARK: - Check In Today

  @MainActor
  func testCheckInToday_Success() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 5,
      bestStreak: 10,
      totalCheckIns: 6,
      todayCompleted: false
    )

    mockCheckInsAPIClient.checkInToTodayResult = CheckIn(
      id: 1,
      habitId: habit.id,
      userId: 1,
      checkInDate: "2026-08-20",
      createdAt: "2026-08-20T10:00:00Z"
    )

    mockCheckInRepository.getCheckInsResult = [
      CheckIn(
        id: 1,
        habitId: habit.id,
        userId: 1,
        checkInDate: "2026-08-20",
        createdAt: "2026-08-20T10:00:00Z"
      ),
    ]

    mockHabitsAPIClient.getHabitResult = createTestHabit(id: habit.id, status: .active)

    sut.allHabits = [habit]

    await sut.checkInToday(habit)

    XCTAssertEqual(mockCheckInsAPIClient.checkInToTodayCallCount, 1)
    XCTAssertEqual(mockCheckInsAPIClient.lastCheckInHabitId, habit.id)
    XCTAssertNil(sut.checkingInHabitId)
    XCTAssertNil(sut.checkInErrors[habit.id])
  }

  @MainActor
  func testCheckInToday_SetLoadingState() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      todayCompleted: false
    )

    mockCheckInsAPIClient.checkInToTodayDelay = 0.1
    mockCheckInRepository.getCheckInsResult = []
    mockHabitsAPIClient.getHabitResult = createTestHabit(id: habit.id, status: .active)

    sut.allHabits = [habit]

    let checkTask = Task {
      await sut.checkInToday(habit)
    }

    try? await Task.sleep(for: .milliseconds(50))
    XCTAssertEqual(sut.checkingInHabitId, habit.id)

    await checkTask.value
    XCTAssertNil(sut.checkingInHabitId)
  }

  @MainActor
  func testCheckInToday_PreventDuplicateRequests() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      todayCompleted: false
    )

    sut.checkingInHabitId = 999
    sut.allHabits = [habit]

    await sut.checkInToday(habit)

    XCTAssertEqual(mockCheckInsAPIClient.checkInToTodayCallCount, 0)
  }

  @MainActor
  func testCheckInToday_IgnoreIfAlreadyCompleted() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      todayCompleted: true
    )

    sut.allHabits = [habit]

    await sut.checkInToday(habit)

    XCTAssertEqual(mockCheckInsAPIClient.checkInToTodayCallCount, 0)
  }

  @MainActor
  func testCheckInToday_IgnoreForPausedHabit() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .paused),
      todayCompleted: false
    )

    sut.allHabits = [habit]

    await sut.checkInToday(habit)

    XCTAssertEqual(mockCheckInsAPIClient.checkInToTodayCallCount, 0)
  }

  @MainActor
  func testCheckInToday_IgnoreForArchivedHabit() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .archived),
      todayCompleted: false
    )

    sut.allHabits = [habit]

    await sut.checkInToday(habit)

    XCTAssertEqual(mockCheckInsAPIClient.checkInToTodayCallCount, 0)
  }

  @MainActor
  func testCheckInToday_StoresError() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      todayCompleted: false
    )

    let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
    mockCheckInsAPIClient.checkInToTodayError = testError

    sut.allHabits = [habit]

    await sut.checkInToday(habit)

    XCTAssertEqual(sut.checkInErrors[habit.id], "Network error")
    XCTAssertNil(sut.checkingInHabitId)
  }

  // MARK: - Undo Today's Check-in

  @MainActor
  func testUndoTodaysCheckIn_Success() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 5,
      bestStreak: 10,
      totalCheckIns: 5,
      todayCompleted: true
    )

    mockCheckInRepository.getCheckInsResult = []
    mockHabitsAPIClient.getHabitResult = createTestHabit(id: habit.id, status: .active)

    sut.allHabits = [habit]

    await sut.undoTodaysCheckIn(habit)

    XCTAssertEqual(mockCheckInsAPIClient.undoTodaysCheckInCallCount, 1)
    XCTAssertEqual(mockCheckInsAPIClient.lastUndoHabitId, habit.id)
    XCTAssertNil(sut.checkingInHabitId)
  }

  @MainActor
  func testUndoTodaysCheckIn_PreventDuplicateRequests() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      todayCompleted: true
    )

    sut.checkingInHabitId = 999
    sut.allHabits = [habit]

    await sut.undoTodaysCheckIn(habit)

    XCTAssertEqual(mockCheckInsAPIClient.undoTodaysCheckInCallCount, 0)
  }

  @MainActor
  func testUndoTodaysCheckIn_IgnoreIfNotCompleted() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      todayCompleted: false
    )

    sut.allHabits = [habit]

    await sut.undoTodaysCheckIn(habit)

    XCTAssertEqual(mockCheckInsAPIClient.undoTodaysCheckInCallCount, 0)
  }

  @MainActor
  func testUndoTodaysCheckIn_StoresError() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      todayCompleted: true
    )

    let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to undo"])
    mockCheckInsAPIClient.undoTodaysCheckInError = testError

    sut.allHabits = [habit]

    await sut.undoTodaysCheckIn(habit)

    XCTAssertEqual(sut.checkInErrors[habit.id], "Failed to undo")
  }

  // MARK: - Clear Check-in Error

  @MainActor
  func testClearCheckInError() {
    let habitId = 1
    sut.checkInErrors[habitId] = "Some error"

    sut.clearCheckInError(habitId)

    XCTAssertNil(sut.checkInErrors[habitId])
  }

  // MARK: - Helpers

  private func createTestHabit(
    id: Int = 1,
    name: String = "Test Habit",
    status: HabitStatus = .active
  ) -> Habit {
    Habit(
      id: id,
      name: name,
      description: "Test description",
      startDate: "2026-08-20",
      status: status,
      createdAt: "2026-08-20T10:00:00Z",
      updatedAt: "2026-08-20T10:00:00Z"
    )
  }
}

// MARK: - Mocks

class MockHabitsAPIClient: HabitsAPIClient {
  var getHabitResult: Habit?
  var getHabitError: Error?
  var getHabitCallCount = 0
  var lastGetHabitId: Int?

  override func getHabit(id: Int) async throws -> Habit {
    getHabitCallCount += 1
    lastGetHabitId = id

    if let error = getHabitError {
      throw error
    }

    guard let result = getHabitResult else {
      throw NSError(domain: "mock", code: 1, userInfo: nil)
    }

    return result
  }
}

class MockCheckInsAPIClient: CheckInsAPIClient {
  var checkInToTodayResult: CheckIn?
  var checkInToTodayError: Error?
  var checkInToTodayCallCount = 0
  var checkInToTodayDelay: TimeInterval = 0
  var lastCheckInHabitId: Int?

  var getCheckInsResult: [CheckIn] = []
  var getCheckInsError: Error?
  var getCheckInsCallCount = 0
  var getCheckInsOnCall: (() -> Void)?

  var undoTodaysCheckInError: Error?
  var undoTodaysCheckInCallCount = 0
  var lastUndoHabitId: Int?

  override func getCheckIns(habitId: Int) async throws -> [CheckIn] {
    getCheckInsCallCount += 1
    getCheckInsOnCall?()

    if let error = getCheckInsError {
      throw error
    }
    return getCheckInsResult
  }

  override func checkInToday(habitId: Int) async throws -> CheckIn {
    if checkInToTodayDelay > 0 {
      try? await Task.sleep(for: .seconds(checkInToTodayDelay))
    }

    checkInToTodayCallCount += 1
    lastCheckInHabitId = habitId

    if let error = checkInToTodayError {
      throw error
    }

    guard let result = checkInToTodayResult else {
      throw NSError(domain: "mock", code: 1, userInfo: nil)
    }

    return result
  }

  override func undoTodaysCheckIn(habitId: Int) async throws {
    undoTodaysCheckInCallCount += 1
    lastUndoHabitId = habitId

    if let error = undoTodaysCheckInError {
      throw error
    }
  }
}

class MockCheckInRepository: CheckInRepository {
  var getCheckInsResult: [CheckIn] = []
  var getCheckInsError: Error?

  override func getCheckIns(habitId: Int, forceRefresh: Bool = false) async throws -> [CheckIn] {
    if let error = getCheckInsError {
      throw error
    }
    return getCheckInsResult
  }
}
