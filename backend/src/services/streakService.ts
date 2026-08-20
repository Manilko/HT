//
//  streakService.ts
//  Streak Calculation Service
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { CheckIn } from '../repositories/checkInRepository';

export interface StreakStats {
  currentStreak: number;
  bestStreak: number;
  totalCheckIns: number;
}

export function calculateStreaks(checkIns: CheckIn[]): StreakStats {
  const totalCheckIns = checkIns.length;

  if (totalCheckIns === 0) {
    return { currentStreak: 0, bestStreak: 0, totalCheckIns: 0 };
  }

  const sortedCheckIns = sortCheckInsByDate(checkIns);
  const dates = sortedCheckIns.map((ci) => ci.check_in_date);

  const { current, best } = calculateConsecutiveStreaks(dates);

  return {
    currentStreak: current,
    bestStreak: best,
    totalCheckIns,
  };
}

function sortCheckInsByDate(checkIns: CheckIn[]): CheckIn[] {
  return [...checkIns].sort((a, b) => a.check_in_date.localeCompare(b.check_in_date));
}

function calculateConsecutiveStreaks(
  dates: string[],
): { current: number; best: number } {
  if (dates.length === 0) {
    return { current: 0, best: 0 };
  }

  const today = getToday();
  let currentStreak = 0;
  let bestStreak = 0;
  let streak = 1;

  for (let i = 1; i < dates.length; i++) {
    const prevDate = dates[i - 1];
    const currDate = dates[i];

    if (isConsecutiveDay(prevDate, currDate)) {
      streak += 1;
    } else {
      bestStreak = Math.max(bestStreak, streak);
      streak = 1;
    }
  }

  bestStreak = Math.max(bestStreak, streak);

  // Check if current streak extends to today
  const lastDate = dates[dates.length - 1];
  if (isDateTodayOrYesterday(lastDate, today)) {
    currentStreak = streak;
  } else {
    currentStreak = 0;
  }

  return { current: currentStreak, best: bestStreak };
}

function isConsecutiveDay(prevDateStr: string, currDateStr: string): boolean {
  const prevDate = new Date(prevDateStr);
  const currDate = new Date(currDateStr);

  prevDate.setHours(0, 0, 0, 0);
  currDate.setHours(0, 0, 0, 0);

  const oneDayMs = 24 * 60 * 60 * 1000;
  return currDate.getTime() - prevDate.getTime() === oneDayMs;
}

function isDateTodayOrYesterday(dateStr: string, today: Date): boolean {
  const date = new Date(dateStr);
  date.setHours(0, 0, 0, 0);

  const todayDate = new Date(today);
  todayDate.setHours(0, 0, 0, 0);

  const yesterday = new Date(todayDate);
  yesterday.setDate(yesterday.getDate() - 1);

  return date.getTime() === todayDate.getTime() || date.getTime() === yesterday.getTime();
}

function getToday(): Date {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return today;
}
