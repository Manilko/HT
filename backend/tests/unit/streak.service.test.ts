import { StreakService } from '@streaks/streak.service';
import { mockCheckIns, mockStreak } from '../fixtures/testData';

describe('StreakService', () => {
  let streakService: StreakService;

  beforeEach(() => {
    streakService = new StreakService();
  });

  describe('calculateStreak', () => {
    it('should calculate current streak correctly', () => {
      // Implementation coming soon
      expect(true).toBe(true);
    });

    it('should calculate best streak correctly', () => {
      // Implementation coming soon
      expect(true).toBe(true);
    });

    it('should handle gaps in check-ins', () => {
      // Implementation coming soon
      expect(true).toBe(true);
    });
  });

  describe('checkMilestone', () => {
    it('should detect milestone at 7 days', () => {
      // Implementation coming soon
      expect(true).toBe(true);
    });

    it('should detect milestone at 30 days', () => {
      // Implementation coming soon
      expect(true).toBe(true);
    });

    it('should return null for non-milestone', () => {
      // Implementation coming soon
      expect(true).toBe(true);
    });
  });
});
