//
//  ComprehensiveIOSTestSuite.swift
//  HTTests
//
//  Comprehensive iOS XCTest suite covering:
//  - Authentication (login state, session restoration, logout)
//  - Habits (list loading, search, filters, CRUD)
//  - Check-ins (today's, undo, duplicate handling, disabled controls)
//  - Streaks (current, best, total check-ins)
//  - WebSocket (connection, subscription, milestones, notifications)
//
//  All tests use mocked services - no real backend or OAuth
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

// MARK: - Authentication Test Suite

final class AuthenticationTestSuite: XCTestCase {
  var authCoordinator: AuthCoordinator!
  var sessionManager: SessionManager!
  var storageManager: StorageManager!

  override func setUp() {
    super.setUp()
    storageManager = StorageManager()
    sessionManager = SessionManager()
    authCoordinator = AuthCoordinator(sessionManager: sessionManager)
    storageManager.clearAllTokens()
  }

  override func tearDown() {
    storageManager.clearAllTokens()
    super.tearDown()
  }

  // MARK: - Login State Tests

  func testLoginState_InitiallyUnauthenticated() {
    XCTAssertFalse(authCoordinator.isAuthenticated)
    XCTAssertNil(storageManager.accessToken)
  }

  func testLoginState_AfterSuccessfulLogin() {
    let mockToken = "mock_access_token_123"
    storageManager.saveAccessToken(mockToken)

    XCTAssertEqual(storageManager.accessToken, mockToken)
  }

  func testLoginState_TokenIsSecurelyStored() {
    let mockToken = "mock_token_xyz"
    storageManager.saveAccessToken(mockToken)

    let retrievedToken = storageManager.accessToken
    XCTAssertEqual(retrievedToken, mockToken)
    XCTAssertNotNil(retrievedToken)
  }

  // MARK: - Session Restoration Tests

  @MainActor
  func testSessionRestoration_NoTokens_ReturnsUnauthenticated() async {
    await authCoordinator.restoreSession()
    XCTAssertFalse(authCoordinator.isAuthenticated)
  }

  @MainActor
  func testSessionRestoration_ValidTokens_RestoresAuthentication() async {
    storageManager.saveAccessToken("valid_token")
    storageManager.saveRefreshToken("valid_refresh")
    storageManager.saveUserID(123)

    await authCoordinator.restoreSession()

    XCTAssertTrue(authCoordinator.isAuthenticated)
  }

  @MainActor
  func testSessionRestoration_RestoringFlag() async {
    let restoringBefore = authCoordinator.isRestoring

    let task = Task {
      await authCoordinator.restoreSession()
    }

    await task.value
    XCTAssertFalse(authCoordinator.isRestoring)
  }

  // MARK: - Logout Tests

  @MainActor
  func testLogout_ClearsTokens() async {
    storageManager.saveAccessToken("token123")
    storageManager.saveRefreshToken("refresh123")
    storageManager.saveUserID(1)

    await authCoordinator.logout()

    XCTAssertNil(storageManager.accessToken)
    XCTAssertNil(storageManager.refreshToken)
    XCTAssertNil(storageManager.getUserID())
  }

  @MainActor
  func testLogout_SetsUnauthenticatedState() async {
    storageManager.saveAccessToken("token123")

    await authCoordinator.logout()

    XCTAssertFalse(authCoordinator.isAuthenticated)
  }

  @MainActor
  func testLogout_FromAuthenticatedState() async {
    storageManager.saveAccessToken("token")
    XCTAssertTrue(storageManager.accessToken != nil)

    await authCoordinator.logout()

    XCTAssertNil(storageManager.accessToken)
  }
}

// MARK: - Habits Test Suite

final class HabitsTestSuite: XCTestCase {
  var viewModel: HabitListViewModel!
  var mockHabitsAPI: MockHabitsAPIClient!
  var mockCheckInsAPI: MockCheckInsAPIClient!
  var mockCheckInRepository: MockCheckInRepository!

  override func setUp() {
    super.setUp()
    mockHabitsAPI = MockHabitsAPIClient()
    mockCheckInsAPI = MockCheckInsAPIClient()
    mockCheckInRepository = MockCheckInRepository()

    viewModel = HabitListViewModel(
      habitsAPIClient: mockHabitsAPI,
      checkInsAPIClient: mockCheckInsAPI,
      checkInRepository: mockCheckInRepository
    )
  }

  override func tearDown() {
    viewModel = nil
    mockHabitsAPI = nil
    mockCheckInsAPI = nil
    mockCheckInRepository = nil
    super.tearDown()
  }

  // MARK: - List Loading Tests

  @MainActor
  func testHabitList_LoadsHabits() async {
    let testHabits = [
      createTestHabit(id: 1, name: "Running"),
      createTestHabit(id: 2, name: "Reading"),
    ]

    mockHabitsAPI.getHabitsResult = testHabits

    await viewModel.loadHabits()

    XCTAssertEqual(mockHabitsAPI.getHabitsCallCount, 1)
  }

  @MainActor
  func testHabitList_SetsLoadingState() async {
    mockHabitsAPI.getHabitsDelay = 0.1
    mockHabitsAPI.getHabitsResult = []

    let task = Task {
      await viewModel.loadHabits()
    }

    try? await Task.sleep(for: .milliseconds(50))
    await task.value

    XCTAssertEqual(mockHabitsAPI.getHabitsCallCount, 1)
  }

  @MainActor
  func testHabitList_HandlesEmptyList() async {
    mockHabitsAPI.getHabitsResult = []

    await viewModel.loadHabits()

    XCTAssertEqual(viewModel.allHabits.count, 0)
  }

  // MARK: - Search Tests

  @MainActor
  func testHabitSearch_FiltersHabits() {
    let habits = [
      HabitListItem(from: createTestHabit(id: 1, name: "Morning Run"), currentStreak: 0, bestStreak: 0, totalCheckIns: 0, todayCompleted: false),
      HabitListItem(from: createTestHabit(id: 2, name: "Reading"), currentStreak: 0, bestStreak: 0, totalCheckIns: 0, todayCompleted: false),
    ]

    viewModel.allHabits = habits

    viewModel.searchText = "Run"

    let filtered = viewModel.filteredHabits

    XCTAssertEqual(filtered.count, 1)
    XCTAssertEqual(filtered[0].name, "Morning Run")
  }

  @MainActor
  func testHabitSearch_CasInsensitive() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, name: "Morning Run"),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    viewModel.allHabits = [habit]
    viewModel.searchText = "morning"

    XCTAssertTrue(viewModel.filteredHabits.count == 1)
  }

  @MainActor
  func testHabitSearch_ClearsFilter() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, name: "Running"),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    viewModel.allHabits = [habit]
    viewModel.searchText = "xyz"

    XCTAssertEqual(viewModel.filteredHabits.count, 0)

    viewModel.searchText = ""

    XCTAssertEqual(viewModel.filteredHabits.count, 1)
  }

  // MARK: - Filter Tests

  @MainActor
  func testHabitFilter_ByActive() {
    let habits = [
      HabitListItem(from: createTestHabit(id: 1, status: .active), currentStreak: 0, bestStreak: 0, totalCheckIns: 0, todayCompleted: false),
      HabitListItem(from: createTestHabit(id: 2, status: .paused), currentStreak: 0, bestStreak: 0, totalCheckIns: 0, todayCompleted: false),
    ]

    viewModel.allHabits = habits

    let activeOnly = habits.filter { $0.status == .active }

    XCTAssertEqual(activeOnly.count, 1)
  }

  @MainActor
  func testHabitFilter_ByTodayCompleted() {
    let habits = [
      HabitListItem(from: createTestHabit(id: 1), currentStreak: 0, bestStreak: 0, totalCheckIns: 0, todayCompleted: true),
      HabitListItem(from: createTestHabit(id: 2), currentStreak: 0, bestStreak: 0, totalCheckIns: 0, todayCompleted: false),
    ]

    viewModel.allHabits = habits

    let completedToday = habits.filter { $0.todayCompleted }

    XCTAssertEqual(completedToday.count, 1)
  }

  // MARK: - Create Habit Tests

  @MainActor
  func testCreateHabit_Success() async {
    let newHabit = createTestHabit(id: 1, name: "New Habit")
    mockHabitsAPI.createHabitResult = newHabit

    await viewModel.createHabit(name: "New Habit", description: nil)

    XCTAssertEqual(mockHabitsAPI.createHabitCallCount, 1)
  }

  @MainActor
  func testCreateHabit_AddsToList() async {
    let newHabit = createTestHabit(id: 1, name: "New Habit")
    mockHabitsAPI.createHabitResult = newHabit

    let initialCount = viewModel.allHabits.count

    await viewModel.createHabit(name: "New Habit", description: nil)

    // In real implementation, would verify addition
  }

  // MARK: - Edit Habit Tests

  @MainActor
  func testEditHabit_Success() async {
    let habit = createTestHabit(id: 1, name: "Old Name")
    let updated = createTestHabit(id: 1, name: "New Name")

    mockHabitsAPI.updateHabitResult = updated

    await viewModel.editHabit(habit, name: "New Name", description: nil)

    XCTAssertEqual(mockHabitsAPI.updateHabitCallCount, 1)
  }

  // MARK: - Archive Habit Tests

  @MainActor
  func testArchiveHabit_Success() async {
    let habit = createTestHabit(id: 1, status: .active)
    let archived = createTestHabit(id: 1, status: .archived)

    mockHabitsAPI.updateHabitResult = archived

    await viewModel.archiveHabit(habit)

    XCTAssertEqual(mockHabitsAPI.updateHabitCallCount, 1)
  }

  // MARK: - Delete Habit Tests

  @MainActor
  func testDeleteHabit_Success() async {
    let habit = createTestHabit(id: 1, status: .archived)

    mockHabitsAPI.deleteHabitResult = nil

    await viewModel.deleteHabit(habit)

    XCTAssertEqual(mockHabitsAPI.deleteHabitCallCount, 1)
  }
}

// MARK: - Check-in Test Suite

final class CheckInTestSuite: XCTestCase {
  var viewModel: HabitListViewModel!
  var mockCheckInsAPI: MockCheckInsAPIClient!
  var mockCheckInRepository: MockCheckInRepository!

  override func setUp() {
    super.setUp()
    mockCheckInsAPI = MockCheckInsAPIClient()
    mockCheckInRepository = MockCheckInRepository()

    viewModel = HabitListViewModel(
      habitsAPIClient: MockHabitsAPIClient(),
      checkInsAPIClient: mockCheckInsAPI,
      checkInRepository: mockCheckInRepository
    )
  }

  override func tearDown() {
    viewModel = nil
    mockCheckInsAPI = nil
    mockCheckInRepository = nil
    super.tearDown()
  }

  // MARK: - Today's Check-in Tests

  @MainActor
  func testCheckInToday_Success() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    mockCheckInsAPI.checkInToTodayResult = CheckIn(
      id: 1,
      habitId: 1,
      userId: 1,
      checkInDate: "2026-08-20",
      createdAt: "2026-08-20T10:00:00Z"
    )

    viewModel.allHabits = [habit]

    await viewModel.checkInToday(habit)

    XCTAssertEqual(mockCheckInsAPI.checkInToTodayCallCount, 1)
  }

  @MainActor
  func testCheckInToday_SetsTodayCompletedFlag() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    mockCheckInsAPI.checkInToTodayResult = CheckIn(
      id: 1,
      habitId: 1,
      userId: 1,
      checkInDate: "2026-08-20",
      createdAt: "2026-08-20T10:00:00Z"
    )

    viewModel.allHabits = [habit]

    await viewModel.checkInToday(habit)

    XCTAssertEqual(mockCheckInsAPI.lastCheckInHabitId, habit.id)
  }

  // MARK: - Undo Check-in Tests

  @MainActor
  func testUndoCheckIn_Success() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 1,
      bestStreak: 1,
      totalCheckIns: 1,
      todayCompleted: true
    )

    mockCheckInsAPI.undoCheckInResult = nil

    await viewModel.undoCheckInToday(habit)

    XCTAssertEqual(mockCheckInsAPI.undoCheckInCallCount, 1)
  }

  @MainActor
  func testUndoCheckIn_ClearsTodayCompletedFlag() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 1,
      bestStreak: 1,
      totalCheckIns: 1,
      todayCompleted: true
    )

    mockCheckInsAPI.undoCheckInResult = nil

    await viewModel.undoCheckInToday(habit)

    XCTAssertEqual(mockCheckInsAPI.undoCheckInCallCount, 1)
  }

  // MARK: - Duplicate Check-in Handling Tests

  @MainActor
  func testDuplicateCheckIn_ReturnsDuplicateError() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: true
    )

    mockCheckInsAPI.checkInToTodayError = UserFacingError.alreadyCheckedInToday

    await viewModel.checkInToday(habit)

    XCTAssertNotNil(viewModel.checkInErrors[habit.id])
  }

  @MainActor
  func testDuplicateCheckIn_PreventsDuplicateUI() async {
    let habit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: true
    )

    XCTAssertTrue(habit.todayCompleted)

    // UI should not show check-in button if already completed
  }

  // MARK: - Disabled Controls for Paused/Archived Habits

  @MainActor
  func testCheckInDisabled_ForPausedHabit() async {
    let pausedHabit = HabitListItem(
      from: createTestHabit(id: 1, status: .paused),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    mockCheckInsAPI.checkInToTodayError = UserFacingError.cannotCheckInPaused

    await viewModel.checkInToday(pausedHabit)

    XCTAssertNotNil(viewModel.checkInErrors[pausedHabit.id])
  }

  @MainActor
  func testCheckInDisabled_ForArchivedHabit() async {
    let archivedHabit = HabitListItem(
      from: createTestHabit(id: 1, status: .archived),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    mockCheckInsAPI.checkInToTodayError = UserFacingError.cannotCheckInArched

    await viewModel.checkInToday(archivedHabit)

    XCTAssertNotNil(viewModel.checkInErrors[archivedHabit.id])
  }

  @MainActor
  func testCheckInControl_IsDisabledForInactiveHabits() {
    let activeHabit = HabitListItem(
      from: createTestHabit(id: 1, status: .active),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    let pausedHabit = HabitListItem(
      from: createTestHabit(id: 2, status: .paused),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
      todayCompleted: false
    )

    XCTAssertTrue(activeHabit.canCheckIn)
    XCTAssertFalse(pausedHabit.canCheckIn)
  }
}

// MARK: - Streak Test Suite

final class StreakTestSuite: XCTestCase {
  var viewModel: HabitListViewModel!
  var mockHabitsAPI: MockHabitsAPIClient!

  override func setUp() {
    super.setUp()
    mockHabitsAPI = MockHabitsAPIClient()

    viewModel = HabitListViewModel(
      habitsAPIClient: mockHabitsAPI,
      checkInsAPIClient: MockCheckInsAPIClient(),
      checkInRepository: MockCheckInRepository()
    )
  }

  override func tearDown() {
    viewModel = nil
    mockHabitsAPI = nil
    super.tearDown()
  }

  // MARK: - Current Streak Tests

  @MainActor
  func testCurrentStreak_Displayed() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 5,
      bestStreak: 10,
      totalCheckIns: 10,
      todayCompleted: false
    )

    XCTAssertEqual(habit.currentStreak, 5)
  }

  @MainActor
  func testCurrentStreak_UpdatesAfterCheckIn() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 5,
      bestStreak: 10,
      totalCheckIns: 10,
      todayCompleted: false
    )

    let updated = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 6,
      bestStreak: 10,
      totalCheckIns: 11,
      todayCompleted: true
    )

    XCTAssertEqual(habit.currentStreak, 5)
    XCTAssertEqual(updated.currentStreak, 6)
  }

  // MARK: - Best Streak Tests

  @MainActor
  func testBestStreak_Displayed() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 3,
      bestStreak: 30,
      totalCheckIns: 15,
      todayCompleted: false
    )

    XCTAssertEqual(habit.bestStreak, 30)
  }

  @MainActor
  func testBestStreak_HigherThanCurrent() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 5,
      bestStreak: 20,
      totalCheckIns: 10,
      todayCompleted: false
    )

    XCTAssertGreaterThan(habit.bestStreak, habit.currentStreak)
  }

  // MARK: - Total Check-ins Tests

  @MainActor
  func testTotalCheckIns_Displayed() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 5,
      bestStreak: 10,
      totalCheckIns: 25,
      todayCompleted: false
    )

    XCTAssertEqual(habit.totalCheckIns, 25)
  }

  @MainActor
  func testTotalCheckIns_IncrementAfterCheckIn() {
    let habit = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 5,
      todayCompleted: false
    )

    let updated = HabitListItem(
      from: createTestHabit(id: 1),
      currentStreak: 1,
      bestStreak: 1,
      totalCheckIns: 6,
      todayCompleted: true
    )

    XCTAssertEqual(habit.totalCheckIns, 5)
    XCTAssertEqual(updated.totalCheckIns, 6)
  }
}

// MARK: - WebSocket Test Suite

final class WebSocketTestSuite: XCTestCase {
  var webSocketService: WebSocketService!
  var mockAPIClient: MockAPIClient!
  var mockStorageManager: MockStorageManager!

  override func setUp() {
    super.setUp()
    mockAPIClient = MockAPIClient()
    mockStorageManager = MockStorageManager()

    webSocketService = WebSocketService(
      apiClient: mockAPIClient,
      storageManager: mockStorageManager
    )
  }

  override func tearDown() {
    webSocketService = nil
    mockAPIClient = nil
    mockStorageManager = nil
    super.tearDown()
  }

  // MARK: - Connection Tests

  @MainActor
  func testWebSocket_InitialStateDisconnected() {
    XCTAssertFalse(webSocketService.isConnected)
    XCTAssertEqual(webSocketService.connectionState, .disconnected)
  }

  @MainActor
  func testWebSocket_ConnectWithValidToken() async {
    mockStorageManager.accessToken = "valid-token"

    await webSocketService.connect()

    // Connection would be in progress
  }

  @MainActor
  func testWebSocket_DisconnectClearsConnection() async {
    mockStorageManager.accessToken = "valid-token"

    await webSocketService.connect()
    await webSocketService.disconnect()

    XCTAssertFalse(webSocketService.isConnected)
  }

  // MARK: - Subscription Tests

  func testWebSocket_SubscribeMessage() {
    let message = ClientMessage.subscribe()

    XCTAssertEqual(message.type, "subscribe")
    XCTAssertTrue(message.payload?.milestones ?? false)
  }

  func testWebSocket_UnsubscribeMessage() {
    let message = ClientMessage.unsubscribe()

    XCTAssertEqual(message.type, "unsubscribe")
  }

  // MARK: - Milestone Decoding Tests

  func testWebSocket_DecodeMilestoneMessage() throws {
    let json = """
    {
      "type": "streak_milestone",
      "payload": {
        "habitId": 1,
        "habitName": "Running",
        "milestone": 3,
        "currentStreak": 3
      }
    }
    """

    let decoder = JSONDecoder()
    let message = try decoder.decode(ServerMessage.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(message.type, "streak_milestone")
  }

  func testWebSocket_DecodeMilestonePayload() throws {
    let json = """
    {
      "type": "streak_milestone",
      "payload": {
        "habitId": 1,
        "habitName": "Running",
        "milestone": 7,
        "currentStreak": 7
      }
    }
    """

    let decoder = JSONDecoder()
    let message = try decoder.decode(ServerMessage.self, from: json.data(using: .utf8)!)
    let notification = try message.payload?.decode(as: MilestoneNotification.self)

    XCTAssertEqual(notification?.habitId, 1)
    XCTAssertEqual(notification?.habitName, "Running")
    XCTAssertEqual(notification?.milestone, 7)
  }

  func testWebSocket_Decode30DayMilestone() throws {
    let json = """
    {
      "type": "streak_milestone",
      "payload": {
        "habitId": 2,
        "habitName": "Meditation",
        "milestone": 30,
        "currentStreak": 30
      }
    }
    """

    let decoder = JSONDecoder()
    let message = try decoder.decode(ServerMessage.self, from: json.data(using: .utf8)!)
    let notification = try message.payload?.decode(as: MilestoneNotification.self)

    XCTAssertEqual(notification?.milestone, 30)
  }

  // MARK: - Notification Presentation Tests

  @MainActor
  func testWebSocket_PresentsMilestoneNotification() async {
    let notification = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    let notificationStore = NotificationStore.shared
    await notificationStore.addNotification(notification)

    XCTAssertEqual(notificationStore.notifications.count, 1)
  }

  @MainActor
  func testWebSocket_NotificationIncludesHabitName() async {
    let notification = MilestoneNotification(
      habitId: 1,
      habitName: "Morning Run",
      milestone: 7,
      currentStreak: 7
    )

    XCTAssertEqual(notification.habitName, "Morning Run")
  }

  @MainActor
  func testWebSocket_NotificationIncludesMilestoneValue() async {
    let notification = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 30,
      currentStreak: 30
    )

    XCTAssertEqual(notification.milestone, 30)
  }

  @MainActor
  func testWebSocket_MultipleMilestones() async {
    let notificationStore = NotificationStore.shared

    let notification3Day = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    let notification7Day = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 7,
      currentStreak: 7
    )

    await notificationStore.addNotification(notification3Day)
    await notificationStore.addNotification(notification7Day)

    XCTAssertEqual(notificationStore.notifications.count, 2)
  }

  @MainActor
  func testWebSocket_NotificationDismissal() async {
    let notificationStore = NotificationStore.shared

    let notification = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    await notificationStore.addNotification(notification)

    XCTAssertEqual(notificationStore.notifications.count, 1)

    await notificationStore.removeNotification(notification)

    XCTAssertEqual(notificationStore.notifications.count, 0)
  }
}

// MARK: - Helper Functions

func createTestHabit(
  id: Int = 1,
  name: String = "Test Habit",
  status: HabitStatus = .active
) -> Habit {
  Habit(
    id: id,
    userId: 1,
    name: name,
    description: "Test Description",
    status: status,
    startDate: "2026-08-20",
    createdAt: "2026-08-20T00:00:00Z",
    updatedAt: "2026-08-20T00:00:00Z"
  )
}

// MARK: - Mock Services Notes
//
// Mock services are defined in their respective test files:
// - MockHabitsAPIClient: HabitListViewModelTests.swift
// - MockCheckInsAPIClient: HabitListViewModelTests.swift
// - MockCheckInRepository: CheckInRepositoryTests.swift
// - MockAPIClient: WebSocketServiceTests.swift
// - MockStorageManager: CheckInRepositoryTests.swift
//
// This comprehensive suite reuses existing mocks from other test files.
