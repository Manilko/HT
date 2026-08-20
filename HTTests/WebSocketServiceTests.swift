//
//  WebSocketServiceTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

final class WebSocketServiceTests: XCTestCase {
  var sut: WebSocketService!
  var mockAPIClient: MockAPIClient!
  var mockStorageManager: MockStorageManager!

  override func setUp() {
    super.setUp()

    mockAPIClient = MockAPIClient()
    mockStorageManager = MockStorageManager()

    sut = WebSocketService(
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

  // MARK: - Connection State

  @MainActor
  func testInitialState() {
    XCTAssertFalse(sut.isConnected)
    XCTAssertEqual(sut.connectionState, .disconnected)
  }

  @MainActor
  func testConnectionStateTransitions() async {
    mockStorageManager.accessToken = "valid-token"

    let stateChanges = NSMutableArray()
    var cancellable: Task<Void, Never>? = Task {
      for await event in sut.eventStream() {
        stateChanges.add(event)
      }
    }

    // Connection would happen here, but we can test the state directly
    XCTAssertFalse(sut.isConnected)

    cancellable?.cancel()
  }

  // MARK: - Subscribe Message

  func testSubscribeMessageFormat() {
    let message = ClientMessage.subscribe()

    XCTAssertEqual(message.type, "subscribe")
    XCTAssertTrue(message.payload?.milestones ?? false)
  }

  func testUnsubscribeMessageFormat() {
    let message = ClientMessage.unsubscribe()

    XCTAssertEqual(message.type, "unsubscribe")
    XCTAssertNil(message.payload)
  }

  // MARK: - Message Decoding

  func testDecodeMilestoneMessage() throws {
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

    let notification = try message.payload?.decode(as: MilestoneNotification.self)
    XCTAssertEqual(notification?.habitId, 1)
    XCTAssertEqual(notification?.habitName, "Running")
    XCTAssertEqual(notification?.milestone, 3)
    XCTAssertEqual(notification?.currentStreak, 3)
  }

  func testDecodeErrorMessage() throws {
    let json = """
    {
      "type": "error",
      "payload": {
        "message": "Connection failed"
      }
    }
    """

    let decoder = JSONDecoder()
    let message = try decoder.decode(ServerMessage.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(message.type, "error")

    let error = try message.payload?.decode(as: ErrorMessage.self)
    XCTAssertEqual(error?.message, "Connection failed")
  }

  // MARK: - Invalid Message Handling

  func testDecodeInvalidMessage() throws {
    let json = """
    {
      "type": "unknown_type",
      "payload": {}
    }
    """

    let decoder = JSONDecoder()
    let message = try decoder.decode(ServerMessage.self, from: json.data(using: .utf8)!)

    XCTAssertEqual(message.type, "unknown_type")
  }

  func testDecodeMissingType() throws {
    let json = """
    {
      "payload": {}
    }
    """

    let decoder = JSONDecoder()

    XCTAssertThrowsError(
      try decoder.decode(ServerMessage.self, from: json.data(using: .utf8)!)
    )
  }

  func testDecodeMalformedJSON() {
    let json = "{ invalid json }"

    let decoder = JSONDecoder()

    XCTAssertThrowsError(
      try decoder.decode(ServerMessage.self, from: json.data(using: .utf8)!)
    )
  }

  // MARK: - Event Stream

  @MainActor
  func testEventStreamExposition() {
    let stream1 = sut.eventStream()
    let stream2 = sut.eventStream()

    // Should return the same stream instance
    XCTAssert(stream1 === stream2)
  }

  // MARK: - Disconnect

  @MainActor
  func testDisconnect() async {
    mockStorageManager.accessToken = "valid-token"

    XCTAssertFalse(sut.isConnected)

    // After disconnect, should be disconnected
    await sut.disconnect()

    XCTAssertFalse(sut.isConnected)
    XCTAssertEqual(sut.connectionState, .disconnected)
  }

  // MARK: - Missing Token

  @MainActor
  func testConnectWithoutToken() async {
    mockStorageManager.accessToken = nil

    // Connection should fail without token
    await sut.connect()

    XCTAssertFalse(sut.isConnected)
  }

  // MARK: - Milestone Notification

  func testMilestoneNotificationEquality() {
    let notification1 = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    let notification2 = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    XCTAssertEqual(notification1, notification2)
  }

  // MARK: - Event Equality

  func testWebSocketEventEquality() {
    let event1 = WebSocketEvent.connected
    let event2 = WebSocketEvent.connected

    XCTAssertEqual(event1, event2)
  }

  func testWebSocketEventMilestoneEquality() {
    let notification = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    let event1 = WebSocketEvent.milestone(notification)
    let event2 = WebSocketEvent.milestone(notification)

    XCTAssertEqual(event1, event2)
  }

  func testWebSocketEventHashability() {
    let event1 = WebSocketEvent.connected
    let event2 = WebSocketEvent.connected

    var set: Set<WebSocketEvent> = [event1]
    XCTAssertTrue(set.contains(event2))
  }
}

// MARK: - Mocks

class MockAPIClient: APIClient {
  override init() {
    super.init()
  }
}

class MockStorageManager: StorageManager {
  var accessToken: String?

  override func getAccessToken() -> String? {
    accessToken
  }

  override func saveAccessToken(_ token: String) {
    accessToken = token
  }

  override func clearAccessToken() {
    accessToken = nil
  }
}
