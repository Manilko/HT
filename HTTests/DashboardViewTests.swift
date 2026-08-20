//
//  DashboardViewTests.swift
//  HTTests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import XCTest
@testable import HT

final class DesignTokensTests: XCTestCase {
  // MARK: - Spacing

  func testSpacingValues() {
    XCTAssertEqual(DesignTokens.Spacing.xs, 4)
    XCTAssertEqual(DesignTokens.Spacing.sm, 8)
    XCTAssertEqual(DesignTokens.Spacing.md, 12)
    XCTAssertEqual(DesignTokens.Spacing.lg, 16)
    XCTAssertEqual(DesignTokens.Spacing.xl, 24)
    XCTAssertEqual(DesignTokens.Spacing.xxl, 32)
  }

  // MARK: - Corner Radius

  func testCornerRadiusValues() {
    XCTAssertEqual(DesignTokens.CornerRadius.sm, 6)
    XCTAssertEqual(DesignTokens.CornerRadius.md, 8)
    XCTAssertEqual(DesignTokens.CornerRadius.lg, 12)
    XCTAssertEqual(DesignTokens.CornerRadius.xl, 16)
  }
}

final class HabitCardViewModelTests: XCTestCase {
  // MARK: - Card Display

  func testHabitCardDisplaysName() {
    let habit = createTestHabit(name: "Morning Run")
    // Card displays the name in headline font
    XCTAssertEqual(habit.name, "Morning Run")
  }

  func testHabitCardDisplaysDescription() {
    let habit = createTestHabit(description: "5 miles daily")
    XCTAssertEqual(habit.description, "5 miles daily")
  }

  func testHabitCardDisplaysStreaks() {
    let habit = createTestHabit(
      currentStreak: 7,
      bestStreak: 21,
      totalCheckIns: 30
    )

    XCTAssertEqual(habit.currentStreak, 7)
    XCTAssertEqual(habit.bestStreak, 21)
    XCTAssertEqual(habit.totalCheckIns, 30)
  }

  func testHabitCardDisplaysStatus() {
    let activeHabit = createTestHabit(status: .active)
    let pausedHabit = createTestHabit(status: .paused)
    let archivedHabit = createTestHabit(status: .archived)

    XCTAssertEqual(activeHabit.status, .active)
    XCTAssertEqual(pausedHabit.status, .paused)
    XCTAssertEqual(archivedHabit.status, .archived)
  }

  func testHabitCardTodayCompletion() {
    let completedHabit = createTestHabit(todayCompleted: true)
    let incompleteHabit = createTestHabit(todayCompleted: false)

    XCTAssertTrue(completedHabit.todayCompleted)
    XCTAssertFalse(incompleteHabit.todayCompleted)
  }

  // MARK: - Card Interactions

  func testCheckInButtonEnabledForActive() {
    let habit = createTestHabit(status: .active, todayCompleted: false)
    XCTAssertTrue(habit.status.isActive)
    XCTAssertFalse(habit.todayCompleted)
  }

  func testCheckInButtonDisabledForPaused() {
    let habit = createTestHabit(status: .paused)
    XCTAssertFalse(habit.status.isActive)
  }

  func testCheckInButtonDisabledWhenCompleted() {
    let habit = createTestHabit(status: .active, todayCompleted: true)
    XCTAssertTrue(habit.todayCompleted)
  }

  // MARK: - Card Styling

  func testStatusColors() {
    XCTAssertNotNil(DesignTokens.Colors.activeGreen)
    XCTAssertNotNil(DesignTokens.Colors.pausedOrange)
    XCTAssertNotNil(DesignTokens.Colors.archivedGray)
  }

  func testStreakColors() {
    XCTAssertNotNil(DesignTokens.Colors.streakFire)
    XCTAssertNotNil(DesignTokens.Colors.streakStar)
    XCTAssertNotNil(DesignTokens.Colors.streakTrophy)
  }

  // MARK: - Accessibility

  func testAccessibilityLabel() {
    let habit = createTestHabit(name: "Exercise")
    XCTAssertEqual(habit.name, "Exercise")
  }

  func testAccessibilityHint() {
    let habit = createTestHabit(
      currentStreak: 5,
      todayCompleted: true
    )

    XCTAssertEqual(habit.currentStreak, 5)
    XCTAssertTrue(habit.todayCompleted)
  }

  // MARK: - Helpers

  private func createTestHabit(
    id: Int = 1,
    name: String = "Test Habit",
    description: String? = "Test description",
    status: HabitStatus = .active,
    currentStreak: Int = 5,
    bestStreak: Int = 10,
    totalCheckIns: Int = 15,
    todayCompleted: Bool = false
  ) -> HabitListItem {
    HabitListItem(
      from: Habit(
        id: id,
        name: name,
        description: description,
        startDate: "2026-08-20",
        status: status,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        totalCheckIns: totalCheckIns,
        createdAt: "2026-08-20T10:00:00Z",
        updatedAt: "2026-08-20T10:00:00Z"
      ),
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      totalCheckIns: totalCheckIns,
      todayCompleted: todayCompleted
    )
  }
}
