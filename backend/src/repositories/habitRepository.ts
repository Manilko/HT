//
//  habitRepository.ts
//  Habit Repository
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';
import { logger } from '../config/logger';

export type HabitStatus = 'ACTIVE' | 'PAUSED' | 'ARCHIVED';

export interface Habit {
  id: number;
  user_id: number;
  name: string;
  description: string | null;
  start_date: string;
  status: HabitStatus;
  created_at: string;
  updated_at: string;
}

export interface CreateHabitData {
  name: string;
  description?: string | null;
  start_date: string;
}

export interface UpdateHabitData {
  name?: string;
  description?: string | null;
  status?: HabitStatus;
}

export interface HabitFilterOptions {
  search?: string;
  statuses?: HabitStatus[];
}

export async function createHabit(userId: number, data: CreateHabitData): Promise<Habit> {
  try {
    const result = await query(
      `INSERT INTO habits (user_id, name, description, start_date, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING *`,
      [userId, data.name, data.description || null, data.start_date],
    );

    return result.rows[0] as Habit;
  } catch (error) {
    logger.error(`Failed to create habit for user ${userId}`, error);
    throw error;
  }
}

export async function getHabitsByUserId(userId: number, filters?: HabitFilterOptions): Promise<Habit[]> {
  try {
    let sqlQuery = `SELECT * FROM habits WHERE user_id = $1`;
    const params: unknown[] = [userId];
    let paramIndex = 2;

    // Search filter: search in name and description
    if (filters?.search) {
      const searchTerm = `%${filters.search}%`;
      sqlQuery += ` AND (name ILIKE $${paramIndex} OR description ILIKE $${paramIndex})`;
      params.push(searchTerm);
      paramIndex++;
    }

    // Status filter
    if (filters?.statuses && filters.statuses.length > 0) {
      const statusPlaceholders = filters.statuses.map(() => `$${paramIndex++}`).join(',');
      sqlQuery += ` AND status IN (${statusPlaceholders})`;
      params.push(...filters.statuses);
    }

    sqlQuery += ` ORDER BY created_at DESC`;

    const result = await query(sqlQuery, params);

    return result.rows as Habit[];
  } catch (error) {
    logger.error(`Failed to get habits for user ${userId}`, error);
    throw error;
  }
}

export async function getHabitById(habitId: number): Promise<Habit | null> {
  try {
    const result = await query(`SELECT * FROM habits WHERE id = $1`, [habitId]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0] as Habit;
  } catch (error) {
    logger.error(`Failed to get habit ${habitId}`, error);
    throw error;
  }
}

export async function updateHabit(habitId: number, data: UpdateHabitData): Promise<Habit> {
  try {
    const updates: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (data.name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      values.push(data.name);
    }

    if (data.description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      values.push(data.description);
    }

    if (data.status !== undefined) {
      updates.push(`status = $${paramIndex++}`);
      values.push(data.status);
    }

    updates.push(`updated_at = CURRENT_TIMESTAMP`);

    const updateClause = updates.join(', ');
    values.push(habitId);

    const result = await query(
      `UPDATE habits SET ${updateClause} WHERE id = $${paramIndex} RETURNING *`,
      values,
    );

    if (result.rows.length === 0) {
      throw new Error('Habit not found');
    }

    return result.rows[0] as Habit;
  } catch (error) {
    logger.error(`Failed to update habit ${habitId}`, error);
    throw error;
  }
}

export async function deleteHabit(habitId: number): Promise<void> {
  const client = await query('BEGIN');

  try {
    // Delete check-ins first (cascade by design, but explicit for clarity)
    await query(`DELETE FROM check_ins WHERE habit_id = $1`, [habitId]);

    // Delete milestone notifications
    await query(`DELETE FROM milestone_notifications WHERE habit_id = $1`, [habitId]);

    // Delete habit
    await query(`DELETE FROM habits WHERE id = $1`, [habitId]);

    await query('COMMIT');
    logger.info(`Deleted habit ${habitId} with cascade`);
  } catch (error) {
    await query('ROLLBACK');
    logger.error(`Failed to delete habit ${habitId}`, error);
    throw error;
  }
}

export async function canUserAccessHabit(userId: number, habitId: number): Promise<boolean> {
  try {
    const result = await query(
      `SELECT id FROM habits WHERE id = $1 AND user_id = $2`,
      [habitId, userId],
    );

    return result.rows.length > 0;
  } catch (error) {
    logger.error(`Failed to check habit access`, error);
    return false;
  }
}

export async function isHabitArchived(habitId: number): Promise<boolean> {
  try {
    const result = await query(`SELECT status FROM habits WHERE id = $1`, [habitId]);

    if (result.rows.length === 0) {
      return false;
    }

    return result.rows[0].status === 'ARCHIVED';
  } catch (error) {
    logger.error(`Failed to check habit archived status`, error);
    return false;
  }
}
