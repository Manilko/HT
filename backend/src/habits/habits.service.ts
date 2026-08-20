import { Habit } from '@types/index';

export class HabitsService {
  async getHabitById(habitId: number, userId: number): Promise<Habit> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async listHabits(userId: number): Promise<Habit[]> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async searchHabits(userId: number, query: string): Promise<Habit[]> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async createHabit(userId: number, data: Partial<Habit>): Promise<Habit> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async updateHabit(habitId: number, userId: number, data: Partial<Habit>): Promise<Habit> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async deleteHabit(habitId: number, userId: number): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
