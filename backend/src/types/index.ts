export interface User {
  id: number;
  email: string;
  displayName: string;
  oauthId: string;
  oauthProvider: 'google' | 'github';
  timezone: string;
  profilePictureUrl?: string;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

export interface Habit {
  id: number;
  userId: number;
  name: string;
  description?: string;
  color?: string;
  frequency: 'daily' | 'weekly';
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date;
}

export interface CheckIn {
  id: number;
  habitId: number;
  userId: number;
  checkInDate: string;
  notes?: string;
  createdAt: Date;
}

export interface Streak {
  id: number;
  habitId: number;
  currentStreakDays: number;
  bestStreakDays: number;
  bestStreakStartDate?: string;
  bestStreakEndDate?: string;
  totalCheckIns: number;
  lastCheckInDate?: string;
  updatedAt: Date;
}

export interface JWTPayload {
  sub: number;
  email: string;
  oauthProvider: 'google' | 'github';
  oauthId: string;
  iat: number;
  exp: number;
  aud: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
  timestamp: string;
}

export interface PaginationParams {
  page: number;
  limit: number;
  offset: number;
}

export interface WebSocketMessage {
  type: string;
  data: Record<string, unknown>;
  timestamp?: string;
}

export interface MilestoneEvent {
  habitId: number;
  habitName: string;
  currentStreak: number;
  milestone: number;
}
