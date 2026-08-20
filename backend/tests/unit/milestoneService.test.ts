//
//  milestoneService.test.ts
//  Milestone Service Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import {
  getMilestoneNotifications,
  recordMilestoneDelivery,
  hasMilestoneBeenDelivered,
  MILESTONE_THRESHOLDS,
} from '../../src/services/milestoneService';
import { CheckIn } from '../../src/repositories/checkInRepository';

// Mock the dependencies
jest.mock('../../src/config/database');
jest.mock('../../src/repositories/checkInRepository');
jest.mock('../../src/repositories/habitRepository');

import * as checkInRepo from '../../src/repositories/checkInRepository';
import * as habitRepo from '../../src/repositories/habitRepository';
import { query } from '../../src/config/database';

describe('Milestone Service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  // MARK: - Milestone Thresholds

  it('should define correct milestone thresholds', () => {
    expect(MILESTONE_THRESHOLDS).toEqual([3, 7, 30]);
  });

  // MARK: - Get Milestone Notifications

  it('should return empty array when user has no habits', async () => {
    (habitRepo.getHabitsByUserId as jest.Mock).mockResolvedValue([]);

    const result = await getMilestoneNotifications(1);

    expect(result).toEqual([]);
  });

  it('should skip archived habits', async () => {
    const habit = {
      id: 1,
      user_id: 1,
      name: 'Test Habit',
      status: 'ARCHIVED',
      start_date: '2026-08-20',
      description: null,
      created_at: '2026-08-20T10:00:00Z',
      updated_at: '2026-08-20T10:00:00Z',
    };

    (habitRepo.getHabitsByUserId as jest.Mock).mockResolvedValue([habit]);

    const result = await getMilestoneNotifications(1);

    expect(result).toEqual([]);
  });

  it('should identify 3-day milestone', async () => {
    const habit = {
      id: 1,
      user_id: 1,
      name: 'Running',
      status: 'ACTIVE',
      start_date: '2026-08-20',
      description: null,
      created_at: '2026-08-20T10:00:00Z',
      updated_at: '2026-08-20T10:00:00Z',
    };

    const checkIns: CheckIn[] = [
      {
        id: 1,
        habit_id: 1,
        user_id: 1,
        check_in_date: getDaysAgoString(2),
        created_at: '2026-08-18T10:00:00Z',
      },
      {
        id: 2,
        habit_id: 1,
        user_id: 1,
        check_in_date: getYesterdayString(),
        created_at: '2026-08-19T10:00:00Z',
      },
      {
        id: 3,
        habit_id: 1,
        user_id: 1,
        check_in_date: getTodayString(),
        created_at: '2026-08-20T10:00:00Z',
      },
    ];

    (habitRepo.getHabitsByUserId as jest.Mock).mockResolvedValue([habit]);
    (checkInRepo.getCheckInsByHabitId as jest.Mock).mockResolvedValue(checkIns);
    (query as jest.Mock).mockResolvedValue({ rows: [] });

    const result = await getMilestoneNotifications(1);

    expect(result).toContainEqual(
      expect.objectContaining({
        habitId: 1,
        habitName: 'Running',
        milestone: 3,
        currentStreak: 3,
      }),
    );
  });

  it('should identify 7-day milestone', async () => {
    const habit = {
      id: 1,
      user_id: 1,
      name: 'Running',
      status: 'ACTIVE',
      start_date: '2026-08-20',
      description: null,
      created_at: '2026-08-20T10:00:00Z',
      updated_at: '2026-08-20T10:00:00Z',
    };

    const checkIns: CheckIn[] = [];
    for (let i = 0; i < 7; i++) {
      checkIns.push({
        id: i + 1,
        habit_id: 1,
        user_id: 1,
        check_in_date: getDaysAgoString(6 - i),
        created_at: `2026-08-${14 + i}T10:00:00Z`,
      });
    }

    (habitRepo.getHabitsByUserId as jest.Mock).mockResolvedValue([habit]);
    (checkInRepo.getCheckInsByHabitId as jest.Mock).mockResolvedValue(checkIns);
    (query as jest.Mock).mockResolvedValue({ rows: [] });

    const result = await getMilestoneNotifications(1);

    expect(result).toContainEqual(
      expect.objectContaining({
        habitId: 1,
        habitName: 'Running',
        milestone: 7,
        currentStreak: 7,
      }),
    );
  });

  it('should identify 30-day milestone', async () => {
    const habit = {
      id: 1,
      user_id: 1,
      name: 'Running',
      status: 'ACTIVE',
      start_date: '2026-08-20',
      description: null,
      created_at: '2026-08-20T10:00:00Z',
      updated_at: '2026-08-20T10:00:00Z',
    };

    const checkIns: CheckIn[] = [];
    for (let i = 0; i < 30; i++) {
      checkIns.push({
        id: i + 1,
        habit_id: 1,
        user_id: 1,
        check_in_date: getDaysAgoString(29 - i),
        created_at: `2026-07-${21 + i}T10:00:00Z`,
      });
    }

    (habitRepo.getHabitsByUserId as jest.Mock).mockResolvedValue([habit]);
    (checkInRepo.getCheckInsByHabitId as jest.Mock).mockResolvedValue(checkIns);
    (query as jest.Mock).mockResolvedValue({ rows: [] });

    const result = await getMilestoneNotifications(1);

    expect(result).toContainEqual(
      expect.objectContaining({
        habitId: 1,
        habitName: 'Running',
        milestone: 30,
        currentStreak: 30,
      }),
    );
  });

  it('should not return notification if already delivered', async () => {
    const habit = {
      id: 1,
      user_id: 1,
      name: 'Running',
      status: 'ACTIVE',
      start_date: '2026-08-20',
      description: null,
      created_at: '2026-08-20T10:00:00Z',
      updated_at: '2026-08-20T10:00:00Z',
    };

    const checkIns: CheckIn[] = [
      {
        id: 1,
        habit_id: 1,
        user_id: 1,
        check_in_date: getDaysAgoString(2),
        created_at: '2026-08-18T10:00:00Z',
      },
      {
        id: 2,
        habit_id: 1,
        user_id: 1,
        check_in_date: getYesterdayString(),
        created_at: '2026-08-19T10:00:00Z',
      },
      {
        id: 3,
        habit_id: 1,
        user_id: 1,
        check_in_date: getTodayString(),
        created_at: '2026-08-20T10:00:00Z',
      },
    ];

    (habitRepo.getHabitsByUserId as jest.Mock).mockResolvedValue([habit]);
    (checkInRepo.getCheckInsByHabitId as jest.Mock).mockResolvedValue(checkIns);
    (query as jest.Mock).mockResolvedValue({ rows: [{ id: 1 }] });

    const result = await getMilestoneNotifications(1);

    expect(result).not.toContainEqual(
      expect.objectContaining({
        habitId: 1,
        milestone: 3,
      }),
    );
  });

  it('should return multiple milestones for same habit', async () => {
    const habit = {
      id: 1,
      user_id: 1,
      name: 'Running',
      status: 'ACTIVE',
      start_date: '2026-08-20',
      description: null,
      created_at: '2026-08-20T10:00:00Z',
      updated_at: '2026-08-20T10:00:00Z',
    };

    const checkIns: CheckIn[] = [];
    for (let i = 0; i < 7; i++) {
      checkIns.push({
        id: i + 1,
        habit_id: 1,
        user_id: 1,
        check_in_date: getDaysAgoString(6 - i),
        created_at: `2026-08-${14 + i}T10:00:00Z`,
      });
    }

    (habitRepo.getHabitsByUserId as jest.Mock).mockResolvedValue([habit]);
    (checkInRepo.getCheckInsByHabitId as jest.Mock).mockResolvedValue(checkIns);
    (query as jest.Mock).mockResolvedValue({ rows: [] });

    const result = await getMilestoneNotifications(1);

    const milestones = result.map((n) => n.milestone).sort();
    expect(milestones).toEqual([3, 7]);
  });

  // MARK: - Record Milestone Delivery

  it('should record milestone delivery', async () => {
    await recordMilestoneDelivery(1, 1, 3);

    expect(query).toHaveBeenCalledWith(
      expect.stringContaining('INSERT INTO milestone_notifications'),
      [1, 1, 3],
    );
  });

  // MARK: - Has Milestone Been Delivered

  it('should return true if milestone already delivered', async () => {
    (query as jest.Mock).mockResolvedValue({ rows: [{ id: 1 }] });

    const result = await hasMilestoneBeenDelivered(1, 1, 3);

    expect(result).toBe(true);
  });

  it('should return false if milestone not delivered', async () => {
    (query as jest.Mock).mockResolvedValue({ rows: [] });

    const result = await hasMilestoneBeenDelivered(1, 1, 3);

    expect(result).toBe(false);
  });

  // MARK: - Helpers

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
