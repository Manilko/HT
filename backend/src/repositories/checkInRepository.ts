//
//  checkInRepository.ts
//  Check-in Repository
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';
import { logger } from '../config/logger';

export interface CheckIn {
  id: number;
  habit_id: number;
  user_id: number;
  check_in_date: string;
  created_at: string;
}

export async function createCheckIn(habitId: number, userId: number, date: string): Promise<CheckIn> {
  const client = await query('BEGIN');

  try {
    // Verify habit exists and belongs to user
    const habitResult = await query(`SELECT id, status FROM habits WHERE id = $1 AND user_id = $2`, [
      habitId,
      userId,
    ]);

    if (habitResult.rows.length === 0) {
      throw new Error('Habit not found or access denied');
    }

    const habit = habitResult.rows[0];

    // Check habit status
    if (habit.status !== 'ACTIVE') {
      throw new Error(`Cannot check in for ${habit.status.toLowerCase()} habit`);
    }

    // Try to insert check-in
    const result = await query(
      `INSERT INTO check_ins (habit_id, user_id, check_in_date, created_at)
       VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
       RETURNING *`,
      [habitId, userId, date],
    );

    await query('COMMIT');
    logger.info(`Created check-in for habit ${habitId} on ${date}`);

    return result.rows[0] as CheckIn;
  } catch (error) {
    await query('ROLLBACK');
    logger.error(`Failed to create check-in for habit ${habitId}`, error);
    throw error;
  }
}

export async function getCheckInsByHabitId(habitId: number, userId: number): Promise<CheckIn[]> {
  try {
    // Verify user owns the habit
    const habitResult = await query(`SELECT id FROM habits WHERE id = $1 AND user_id = $2`, [
      habitId,
      userId,
    ]);

    if (habitResult.rows.length === 0) {
      throw new Error('Habit not found or access denied');
    }

    const result = await query(
      `SELECT * FROM check_ins WHERE habit_id = $1 ORDER BY check_in_date DESC`,
      [habitId],
    );

    return result.rows as CheckIn[];
  } catch (error) {
    logger.error(`Failed to get check-ins for habit ${habitId}`, error);
    throw error;
  }
}

export async function getTodaysCheckIn(habitId: number, userId: number): Promise<CheckIn | null> {
  try {
    // Verify user owns the habit
    const habitResult = await query(`SELECT id FROM habits WHERE id = $1 AND user_id = $2`, [
      habitId,
      userId,
    ]);

    if (habitResult.rows.length === 0) {
      throw new Error('Habit not found or access denied');
    }

    const today = new Date().toISOString().split('T')[0];

    const result = await query(
      `SELECT * FROM check_ins WHERE habit_id = $1 AND check_in_date = $2`,
      [habitId, today],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0] as CheckIn;
  } catch (error) {
    logger.error(`Failed to get today's check-in for habit ${habitId}`, error);
    throw error;
  }
}

export async function deleteCheckIn(checkInId: number, userId: number): Promise<void> {
  try {
    // Verify user owns this check-in
    const result = await query(
      `DELETE FROM check_ins
       WHERE id = $1 AND user_id = $2`,
      [checkInId, userId],
    );

    if (result.rowCount === 0) {
      throw new Error('Check-in not found or access denied');
    }

    logger.info(`Deleted check-in ${checkInId}`);
  } catch (error) {
    logger.error(`Failed to delete check-in ${checkInId}`, error);
    throw error;
  }
}

export async function deleteTodaysCheckIn(habitId: number, userId: number): Promise<void> {
  try {
    // Verify user owns the habit
    const habitResult = await query(`SELECT id FROM habits WHERE id = $1 AND user_id = $2`, [
      habitId,
      userId,
    ]);

    if (habitResult.rows.length === 0) {
      throw new Error('Habit not found or access denied');
    }

    const today = new Date().toISOString().split('T')[0];

    const result = await query(
      `DELETE FROM check_ins WHERE habit_id = $1 AND check_in_date = $2`,
      [habitId, today],
    );

    if (result.rowCount === 0) {
      throw new Error('No check-in found for today');
    }

    logger.info(`Deleted today's check-in for habit ${habitId}`);
  } catch (error) {
    logger.error(`Failed to delete today's check-in for habit ${habitId}`, error);
    throw error;
  }
}

export async function hasCheckedInToday(habitId: number): Promise<boolean> {
  try {
    const today = new Date().toISOString().split('T')[0];

    const result = await query(
      `SELECT id FROM check_ins WHERE habit_id = $1 AND check_in_date = $2`,
      [habitId, today],
    );

    return result.rows.length > 0;
  } catch (error) {
    logger.error(`Failed to check if habit ${habitId} has today's check-in`, error);
    return false;
  }
}
