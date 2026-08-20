//
//  habitService.ts
//  Habit Service with Streak Calculations
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Habit } from '../repositories/habitRepository';
import { CheckIn, getCheckInsByHabitId } from '../repositories/checkInRepository';
import { calculateStreaks, StreakStats } from './streakService';

export interface HabitWithStreaks extends Habit {
  currentStreak: number;
  bestStreak: number;
  totalCheckIns: number;
}

export async function getHabitWithStreaks(habitId: number): Promise<HabitWithStreaks> {
  const { getHabitById } = await import('../repositories/habitRepository');

  const habit = await getHabitById(habitId);
  if (!habit) {
    throw new Error('Habit not found');
  }

  const checkIns = await getCheckInsByHabitId(habitId);
  const stats = calculateStreaks(checkIns);

  return {
    ...habit,
    ...stats,
  };
}

export async function getHabitsWithStreaks(habitIds: number[]): Promise<HabitWithStreaks[]> {
  const { getHabitById } = await import('../repositories/habitRepository');

  const habitsWithStreaks: HabitWithStreaks[] = [];

  for (const habitId of habitIds) {
    try {
      const habitWithStreaks = await getHabitWithStreaks(habitId);
      habitsWithStreaks.push(habitWithStreaks);
    } catch (error) {
      // Skip habits that fail to load
      continue;
    }
  }

  return habitsWithStreaks;
}

export function formatHabitResponse(habit: HabitWithStreaks) {
  return {
    id: habit.id,
    name: habit.name,
    description: habit.description,
    startDate: habit.start_date,
    status: habit.status,
    currentStreak: habit.currentStreak,
    bestStreak: habit.bestStreak,
    totalCheckIns: habit.totalCheckIns,
    createdAt: habit.created_at,
    updatedAt: habit.updated_at,
  };
}
