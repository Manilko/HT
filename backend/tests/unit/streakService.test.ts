//
//  streakService.test.ts
//  Streak Service Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { calculateStreaks, StreakStats } from '../../src/services/streakService';
import { CheckIn } from '../../src/repositories/checkInRepository';

describe('Streak Service', () => {
  // MARK: - Zero Check-ins

  it('should return zero stats for empty check-ins', () => {
    const result = calculateStreaks([]);

    expect(result).toEqual({
      currentStreak: 0,
      bestStreak: 0,
      totalCheckIns: 0,
    });
  });

  // MARK: - Single Check-in

  it('should return current streak of 1 for single check-in today', () => {
    const today = getTodayString();
    const checkIns = [createCheckIn('1', today)];

    const result = calculateStreaks(checkIns);

    expect(result).toEqual({
      currentStreak: 1,
      bestStreak: 1,
      totalCheckIns: 1,
    });
  });

  it('should return current streak of 0 for single check-in yesterday', () => {
    const yesterday = getYesterdayString();
    const checkIns = [createCheckIn('1', yesterday)];

    const result = calculateStreaks(checkIns);

    expect(result).toEqual({
      currentStreak: 0,
      bestStreak: 1,
      totalCheckIns: 1,
    });
  });

  it('should return zero stats for check-in older than yesterday', () => {
    const twoDaysAgo = getDaysAgoString(2);
    const checkIns = [createCheckIn('1', twoDaysAgo)];

    const result = calculateStreaks(checkIns);

    expect(result).toEqual({
      currentStreak: 0,
      bestStreak: 1,
      totalCheckIns: 1,
    });
  });

  // MARK: - Consecutive Days

  it('should calculate consecutive streak correctly', () => {
    const today = getTodayString();
    const yesterday = getYesterdayString();
    const twoDaysAgo = getDaysAgoString(2);

    const checkIns = [
      createCheckIn('1', twoDaysAgo),
      createCheckIn('2', yesterday),
      createCheckIn('3', today),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(3);
    expect(result.bestStreak).toBe(3);
    expect(result.totalCheckIns).toBe(3);
  });

  it('should handle check-ins in random order', () => {
    const today = getTodayString();
    const yesterday = getYesterdayString();
    const twoDaysAgo = getDaysAgoString(2);

    const checkIns = [
      createCheckIn('1', today),
      createCheckIn('2', twoDaysAgo),
      createCheckIn('3', yesterday),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(3);
    expect(result.bestStreak).toBe(3);
    expect(result.totalCheckIns).toBe(3);
  });

  // MARK: - Gaps

  it('should reset current streak on gap before today', () => {
    const today = getTodayString();
    const yesterday = getYesterdayString();
    const fourDaysAgo = getDaysAgoString(4);
    const fiveDaysAgo = getDaysAgoString(5);

    // 5 days ago, 4 days ago (gap of 1), yesterday, today
    const checkIns = [
      createCheckIn('1', fiveDaysAgo),
      createCheckIn('2', fourDaysAgo),
      createCheckIn('3', yesterday),
      createCheckIn('4', today),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(2);
    expect(result.bestStreak).toBe(2);
    expect(result.totalCheckIns).toBe(4);
  });

  it('should calculate best streak with multiple sequences', () => {
    // Sequence 1: 5 days long
    const fiveDaysAgo = getDaysAgoString(5);
    const fourDaysAgo = getDaysAgoString(4);
    const threeDaysAgo = getDaysAgoString(3);
    const twoDaysAgo = getDaysAgoString(2);

    // Gap of 1 day

    const today = getTodayString();
    const yesterday = getYesterdayString();

    const checkIns = [
      createCheckIn('1', fiveDaysAgo),
      createCheckIn('2', fourDaysAgo),
      createCheckIn('3', threeDaysAgo),
      createCheckIn('4', twoDaysAgo),
      // Gap on 1 day ago
      createCheckIn('5', yesterday),
      createCheckIn('6', today),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(2);
    expect(result.bestStreak).toBe(4);
    expect(result.totalCheckIns).toBe(6);
  });

  // MARK: - Current Streak

  it('should break current streak if today not completed', () => {
    const yesterday = getYesterdayString();
    const twoDaysAgo = getDaysAgoString(2);

    const checkIns = [
      createCheckIn('1', twoDaysAgo),
      createCheckIn('2', yesterday),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(0);
    expect(result.bestStreak).toBe(2);
    expect(result.totalCheckIns).toBe(2);
  });

  it('should preserve current streak if yesterday completed', () => {
    const yesterday = getYesterdayString();
    const twoDaysAgo = getDaysAgoString(2);

    const checkIns = [
      createCheckIn('1', twoDaysAgo),
      createCheckIn('2', yesterday),
    ];

    const result = calculateStreaks(checkIns);

    // Yesterday is the latest, so current streak = 2
    expect(result.currentStreak).toBe(2);
    expect(result.bestStreak).toBe(2);
    expect(result.totalCheckIns).toBe(2);
  });

  // MARK: - Best Streak

  it('should not decrease best streak on missed day', () => {
    const today = getTodayString();
    const yesterday = getYesterdayString();
    const threeDaysAgo = getDaysAgoString(3);
    const fourDaysAgo = getDaysAgoString(4);
    const fiveDaysAgo = getDaysAgoString(5);

    // Best streak = 3 (5, 4, 3 days ago)
    // Current streak would be 0 (missed yesterday)
    const checkIns = [
      createCheckIn('1', fiveDaysAgo),
      createCheckIn('2', fourDaysAgo),
      createCheckIn('3', threeDaysAgo),
      // Gap on 2 days ago and yesterday
      createCheckIn('4', today),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(1);
    expect(result.bestStreak).toBe(3);
    expect(result.totalCheckIns).toBe(4);
  });

  // MARK: - Long Sequences

  it('should calculate 30-day streak', () => {
    const checkIns: CheckIn[] = [];

    for (let i = 0; i < 30; i++) {
      const date = getDaysAgoString(29 - i);
      checkIns.push(createCheckIn(`${i + 1}`, date));
    }

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(30);
    expect(result.bestStreak).toBe(30);
    expect(result.totalCheckIns).toBe(30);
  });

  it('should handle 100-day best streak with longer current', () => {
    const checkIns: CheckIn[] = [];
    let checkInId = 1;

    // Best streak: 100 days starting 150 days ago
    for (let i = 0; i < 100; i++) {
      const date = getDaysAgoString(149 - i);
      checkIns.push(createCheckIn(`${checkInId++}`, date));
    }

    // Gap of 49 days

    // Current streak: 20 days (today is 20 days ago from start)
    for (let i = 0; i < 20; i++) {
      const date = getDaysAgoString(19 - i);
      checkIns.push(createCheckIn(`${checkInId++}`, date));
    }

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(20);
    expect(result.bestStreak).toBe(100);
    expect(result.totalCheckIns).toBe(120);
  });

  // MARK: - Removing Today's Check-in

  it('should recalculate streak after removing today check-in', () => {
    const today = getTodayString();
    const yesterday = getYesterdayString();
    const twoDaysAgo = getDaysAgoString(2);

    const checkInsWithToday = [
      createCheckIn('1', twoDaysAgo),
      createCheckIn('2', yesterday),
      createCheckIn('3', today),
    ];

    const resultWith = calculateStreaks(checkInsWithToday);
    expect(resultWith.currentStreak).toBe(3);

    const checkInsWithout = [
      createCheckIn('1', twoDaysAgo),
      createCheckIn('2', yesterday),
    ];

    const resultWithout = calculateStreaks(checkInsWithout);
    expect(resultWithout.currentStreak).toBe(0);
    expect(resultWithout.bestStreak).toBe(2);
  });

  // MARK: - Complex Scenarios

  it('should handle real-world scenario: May 1,2,3,5', () => {
    // May 4 is missing (gap)
    // If May 5 is today: current streak = 0, best streak = 3
    const may1 = '2026-05-01';
    const may2 = '2026-05-02';
    const may3 = '2026-05-03';
    const may5 = '2026-05-05'; // This would be "today"

    const checkIns = [
      createCheckIn('1', may1),
      createCheckIn('2', may2),
      createCheckIn('3', may3),
      // No check-in on May 4
      createCheckIn('4', may5),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(1);
    expect(result.bestStreak).toBe(3);
    expect(result.totalCheckIns).toBe(4);
  });

  it('should handle real-world scenario: May 1,2,3,4,6,7', () => {
    // May 5 is missing
    // If May 7 is today: current streak = 2, best streak = 4
    const may1 = '2026-05-01';
    const may2 = '2026-05-02';
    const may3 = '2026-05-03';
    const may4 = '2026-05-04';
    const may6 = '2026-05-06';
    const may7 = '2026-05-07'; // This would be "today"

    const checkIns = [
      createCheckIn('1', may1),
      createCheckIn('2', may2),
      createCheckIn('3', may3),
      createCheckIn('4', may4),
      // No check-in on May 5
      createCheckIn('5', may6),
      createCheckIn('6', may7),
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(2);
    expect(result.bestStreak).toBe(4);
    expect(result.totalCheckIns).toBe(6);
  });

  it('should handle gaps in long streaks', () => {
    const checkIns: CheckIn[] = [];
    let checkInId = 1;

    // 5-day streak
    for (let i = 0; i < 5; i++) {
      const date = getDaysAgoString(9 - i);
      checkIns.push(createCheckIn(`${checkInId++}`, date));
    }

    // Gap of 3 days (days 4, 3, 2)

    // 2-day streak ending today
    for (let i = 0; i < 2; i++) {
      const date = getDaysAgoString(1 - i);
      checkIns.push(createCheckIn(`${checkInId++}`, date));
    }

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(2);
    expect(result.bestStreak).toBe(5);
    expect(result.totalCheckIns).toBe(7);
  });

  // MARK: - Duplicate Check-ins

  it('should handle multiple check-ins on same day', () => {
    const today = getTodayString();
    const yesterday = getYesterdayString();

    const checkIns = [
      createCheckIn('1', yesterday),
      createCheckIn('2', today),
      createCheckIn('3', today), // Duplicate
      createCheckIn('4', today), // Duplicate
    ];

    const result = calculateStreaks(checkIns);

    expect(result.currentStreak).toBe(2);
    expect(result.bestStreak).toBe(2);
    expect(result.totalCheckIns).toBe(4);
  });

  // MARK: - Helpers

  function createCheckIn(id: string, date: string): CheckIn {
    return {
      id: parseInt(id),
      habit_id: 1,
      user_id: 1,
      check_in_date: date,
      created_at: `${date}T10:00:00Z`,
    };
  }

  function getTodayString(): string {
    const today = new Date();
    return today.toISOString().split('T')[0];
  }

  function getYesterdayString(): string {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    return yesterday.toISOString().split('T')[0];
  }

  function getDaysAgoString(days: number): string {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date.toISOString().split('T')[0];
  }
});
