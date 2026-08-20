import { CheckIn } from '@types/index';

export class CheckInsService {
  async getCheckIns(habitId: number, userId: number, startDate?: string, endDate?: string): Promise<CheckIn[]> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async logCheckIn(habitId: number, userId: number, date: string, notes?: string): Promise<CheckIn> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async deleteCheckIn(habitId: number, userId: number, date: string): Promise<void> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  async getCheckInCount(habitId: number): Promise<number> {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
