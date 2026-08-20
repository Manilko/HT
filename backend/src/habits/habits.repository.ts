import { Habit } from '@types/index';

export class HabitsRepository {
  async findById(habitId: number): Promise<Habit | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async findByUserIdAndName(userId: number, name: string): Promise<Habit | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async findByUserId(userId: number): Promise<Habit[]> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async create(habit: Partial<Habit>): Promise<Habit> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async update(habitId: number, data: Partial<Habit>): Promise<Habit> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async delete(habitId: number): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
