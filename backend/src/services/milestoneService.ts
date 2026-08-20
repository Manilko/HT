//
//  milestoneService.ts
//  Milestone Notification Service
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';
import { logger } from '../config/logger';
import { calculateStreaks } from './streakService';
import { getCheckInsByHabitId } from '../repositories/checkInRepository';
import { getHabitsByUserId } from '../repositories/habitRepository';

export const MILESTONE_THRESHOLDS = [3, 7, 30];

export interface MilestoneNotification {
  habitId: number;
  habitName: string;
  milestone: number;
  currentStreak: number;
}

export async function getMilestoneNotifications(userId: number): Promise<MilestoneNotification[]> {
  const habits = await getHabitsByUserId(userId);
  const notifications: MilestoneNotification[] = [];

  for (const habit of habits) {
    if (habit.status === 'ARCHIVED') {
      continue;
    }

    const checkIns = await getCheckInsByHabitId(habit.id);
    const streaks = calculateStreaks(checkIns);

    for (const milestone of MILESTONE_THRESHOLDS) {
      if (streaks.currentStreak >= milestone) {
        const hasBeenNotified = await hasMilestoneBeenDelivered(userId, habit.id, milestone);

        if (!hasBeenNotified) {
          notifications.push({
            habitId: habit.id,
            habitName: habit.name,
            milestone,
            currentStreak: streaks.currentStreak,
          });
        }
      }
    }
  }

  return notifications;
}

export async function recordMilestoneDelivery(
  userId: number,
  habitId: number,
  milestone: number,
): Promise<void> {
  try {
    await query(
      `INSERT INTO milestone_notifications (user_id, habit_id, milestone, created_at)
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
       ON CONFLICT (user_id, habit_id, milestone) DO NOTHING`,
      [userId, habitId, milestone],
    );

    logger.info(`Recorded milestone ${milestone} for habit ${habitId} user ${userId}`);
  } catch (error) {
    logger.error(`Failed to record milestone delivery`, error);
    throw error;
  }
}

export async function hasMilestoneBeenDelivered(
  userId: number,
  habitId: number,
  milestone: number,
): Promise<boolean> {
  try {
    const result = await query(
      `SELECT id FROM milestone_notifications
       WHERE user_id = $1 AND habit_id = $2 AND milestone = $3`,
      [userId, habitId, milestone],
    );

    return result.rows.length > 0;
  } catch (error) {
    logger.error(`Failed to check milestone delivery status`, error);
    return true;
  }
}

export async function clearMilestonesForHabit(habitId: number): Promise<void> {
  try {
    await query(`DELETE FROM milestone_notifications WHERE habit_id = $1`, [habitId]);
    logger.info(`Cleared milestones for habit ${habitId}`);
  } catch (error) {
    logger.error(`Failed to clear milestones for habit ${habitId}`, error);
    throw error;
  }
}
