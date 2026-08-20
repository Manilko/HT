import { MilestoneEvent } from '@types/index';

export class NotificationsService {
  private milestones = [7, 14, 30, 50, 100];

  isMilestone(streak: number): boolean {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  getNextMilestone(streak: number): number | null {
    // Implementation coming soon
    throw new Error('Not implemented');
  }

  buildMilestoneEvent(habitId: number, habitName: string, streak: number): MilestoneEvent | null {
    // Implementation coming soon
    throw new Error('Not implemented');
  }
}
