import { User, Habit, CheckIn, Streak } from '@types/index';

export const mockUser: User = {
  id: 1,
  email: 'test@example.com',
  displayName: 'Test User',
  oauthId: 'google_123',
  oauthProvider: 'google',
  timezone: 'America/New_York',
  profilePictureUrl: 'https://example.com/pic.jpg',
  createdAt: new Date('2026-08-20T00:00:00Z'),
  updatedAt: new Date('2026-08-20T00:00:00Z'),
};

export const mockHabit: Habit = {
  id: 1,
  userId: 1,
  name: 'Morning Run',
  description: 'Run for 30 minutes every morning',
  color: '#FF5733',
  frequency: 'daily',
  createdAt: new Date('2026-08-20T00:00:00Z'),
  updatedAt: new Date('2026-08-20T00:00:00Z'),
};

export const mockCheckIn: CheckIn = {
  id: 1,
  habitId: 1,
  userId: 1,
  checkInDate: '2026-08-20',
  notes: 'Great run today',
  createdAt: new Date('2026-08-20T08:00:00Z'),
};

export const mockStreak: Streak = {
  id: 1,
  habitId: 1,
  currentStreakDays: 5,
  bestStreakDays: 10,
  bestStreakStartDate: '2026-08-10',
  bestStreakEndDate: '2026-08-20',
  totalCheckIns: 15,
  lastCheckInDate: '2026-08-20',
  updatedAt: new Date('2026-08-20T00:00:00Z'),
};

export const mockCheckIns: CheckIn[] = [
  {
    id: 1,
    habitId: 1,
    userId: 1,
    checkInDate: '2026-08-15',
    createdAt: new Date('2026-08-15T08:00:00Z'),
  },
  {
    id: 2,
    habitId: 1,
    userId: 1,
    checkInDate: '2026-08-14',
    createdAt: new Date('2026-08-14T08:00:00Z'),
  },
  {
    id: 3,
    habitId: 1,
    userId: 1,
    checkInDate: '2026-08-13',
    createdAt: new Date('2026-08-13T08:00:00Z'),
  },
];
