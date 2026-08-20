import { CheckIn } from '@types/index';

export class CheckInsRepository {
  async findByHabitId(habitId: number, startDate?: string, endDate?: string): Promise<CheckIn[]> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async findByHabitIdAndDate(habitId: number, date: string): Promise<CheckIn | null> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async create(checkIn: Partial<CheckIn>): Promise<CheckIn> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async delete(habitId: number, date: string): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async countByHabitId(habitId: number): Promise<number> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
