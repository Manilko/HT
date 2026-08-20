//
//  NotificationStoreTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

final class NotificationStoreTests: XCTestCase {
  var sut: NotificationStore!

  override func setUp() {
    super.setUp()
    sut = NotificationStore()
  }

  override func tearDown() {
    sut.dismissAll()
    sut = nil

    super.tearDown()
  }

  // MARK: - Initial State

  @MainActor
  func testInitialState() {
    XCTAssertNil(sut.currentNotification)
    XCTAssertTrue(sut.notifications.isEmpty)
  }

  // MARK: - Show Notification

  @MainActor
  func testShowNotification() {
    let notification = ToastNotification(
      title: "Test",
      message: "Test message",
      type: .info
    )

    sut.show(notification)

    XCTAssertEqual(sut.currentNotification, notification)
  }

  @MainActor
  func testShowReplacesCurrentNotification() {
    let notification1 = ToastNotification(
      title: "First",
      message: "First message",
      type: .info
    )

    let notification2 = ToastNotification(
      title: "Second",
      message: "Second message",
      type: .success
    )

    sut.show(notification1)
    sut.show(notification2)

    XCTAssertEqual(sut.currentNotification, notification2)
  }

  @MainActor
  func testShowMilestoneNotification() {
    let milestone = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    let notification = ToastNotification.milestone(milestone)
    sut.show(notification)

    XCTAssertEqual(sut.currentNotification?.title, "🔥 3-day streak!")
    XCTAssertTrue(sut.currentNotification?.message.contains("Running") ?? false)
  }

  // MARK: - Dismiss Notification

  @MainActor
  func testDismissNotification() {
    let notification = ToastNotification(
      title: "Test",
      message: "Test message",
      type: .info
    )

    sut.show(notification)
    XCTAssertNotNil(sut.currentNotification)

    sut.dismiss(notification.id)

    XCTAssertNil(sut.currentNotification)
  }

  @MainActor
  func testDismissWrongIdDoesNothing() {
    let notification = ToastNotification(
      title: "Test",
      message: "Test message",
      type: .info
    )

    sut.show(notification)

    let wrongId = UUID()
    sut.dismiss(wrongId)

    XCTAssertEqual(sut.currentNotification, notification)
  }

  // MARK: - Dismiss All

  @MainActor
  func testDismissAll() {
    let notification = ToastNotification(
      title: "Test",
      message: "Test message",
      type: .info
    )

    sut.show(notification)
    sut.dismissAll()

    XCTAssertNil(sut.currentNotification)
  }

  // MARK: - Auto Dismiss

  @MainActor
  func testAutoDismissAfterDuration() async {
    let notification = ToastNotification(
      title: "Test",
      message: "Test message",
      type: .info,
      duration: 0.2
    )

    sut.show(notification)

    XCTAssertNotNil(sut.currentNotification)

    try? await Task.sleep(nanoseconds: 300_000_000)

    XCTAssertNil(sut.currentNotification)
  }

  // MARK: - Notification Types

  @MainActor
  func testMilestoneNotificationType3Days() {
    let milestone = MilestoneNotification(
      habitId: 1,
      habitName: "Exercise",
      milestone: 3,
      currentStreak: 3
    )

    let notification = ToastNotification.milestone(milestone)

    XCTAssertTrue(notification.title.contains("3-day"))
    XCTAssertTrue(notification.title.contains("🔥"))
  }

  @MainActor
  func testMilestoneNotificationType7Days() {
    let milestone = MilestoneNotification(
      habitId: 1,
      habitName: "Exercise",
      milestone: 7,
      currentStreak: 7
    )

    let notification = ToastNotification.milestone(milestone)

    XCTAssertTrue(notification.title.contains("7-day"))
    XCTAssertTrue(notification.title.contains("⭐"))
  }

  @MainActor
  func testMilestoneNotificationType30Days() {
    let milestone = MilestoneNotification(
      habitId: 1,
      habitName: "Exercise",
      milestone: 30,
      currentStreak: 30
    )

    let notification = ToastNotification.milestone(milestone)

    XCTAssertTrue(notification.title.contains("30-day"))
    XCTAssertTrue(notification.title.contains("🏆"))
  }

  // MARK: - Background Color

  func testMilestoneBackgroundColor() {
    XCTAssertEqual(ToastNotification.NotificationType.milestone(days: 3).backgroundColor, "orange")
  }

  func testSuccessBackgroundColor() {
    XCTAssertEqual(ToastNotification.NotificationType.success.backgroundColor, "green")
  }

  func testErrorBackgroundColor() {
    XCTAssertEqual(ToastNotification.NotificationType.error.backgroundColor, "red")
  }

  func testInfoBackgroundColor() {
    XCTAssertEqual(ToastNotification.NotificationType.info.backgroundColor, "blue")
  }
}

final class ToastNotificationTests: XCTestCase {
  // MARK: - Equatability

  func testToastNotificationEquality() {
    let notification1 = ToastNotification(
      title: "Test",
      message: "Test message",
      type: .info
    )

    let notification2 = ToastNotification(
      title: "Test",
      message: "Test message",
      type: .info
    )

    // Different IDs, but same content
    XCTAssertNotEqual(notification1, notification2)
  }

  func testMilestoneNotificationCreation() {
    let milestone = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    let toast = ToastNotification.milestone(milestone)

    XCTAssertTrue(toast.title.contains("3-day"))
    XCTAssertTrue(toast.message.contains("Running"))
    XCTAssertTrue(toast.message.contains("3 consecutive"))
  }

  func testMilestoneNotificationDuration() {
    let milestone = MilestoneNotification(
      habitId: 1,
      habitName: "Running",
      milestone: 3,
      currentStreak: 3
    )

    let toast = ToastNotification.milestone(milestone)

    XCTAssertEqual(toast.duration, 5.0)
  }
}
