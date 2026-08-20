import { Streak } from '@types/index';

export class StreakService {
  async getStreak(habitId: number): Promise<Streak> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async calculateStreak(habitId: number): Promise<Streak> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async updateStreakAfterCheckIn(habitId: number, checkInDate: string): Promise<Streak> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async updateStreakAfterDeleteCheckIn(habitId: number): Promise<Streak> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async checkMilestone(habitId: number, currentStreak: number): Promise<number | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
