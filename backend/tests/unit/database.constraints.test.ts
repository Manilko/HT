//
//  database.constraints.test.ts
//  Database Constraint Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { getPool } from '../../src/config/database';

describe('Database Constraints', () => {
  const pool = getPool();

  beforeAll(async () => {
    // Run migrations before tests
    const { runMigrations } = await import('../../src/migrations/runner');
    try {
      await runMigrations();
    } catch (error) {
      // Migrations may already be run
    }
  });

  afterEach(async () => {
    // Clean up test data after each test
    const client = await pool.connect();
    try {
      await client.query('TRUNCATE TABLE check_ins CASCADE');
      await client.query('TRUNCATE TABLE milestone_notifications CASCADE');
      await client.query('TRUNCATE TABLE habits CASCADE');
      await client.query('TRUNCATE TABLE users CASCADE');
    } finally {
      client.release();
    }
  });

  describe('Users Table Constraints', () => {
    it('should enforce provider + provider_user_id uniqueness', async () => {
      const client = await pool.connect();
      try {
        const user1 = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user123', 'Test User'],
        );

        expect(user1.rows[0].id).toBeDefined();

        // Try to insert duplicate
        const duplicate = client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3)`,
          ['google', 'user123', 'Another User'],
        );

        await expect(duplicate).rejects.toThrow();
      } finally {
        client.release();
      }
    });

    it('should allow multiple users with same provider but different provider_user_id', async () => {
      const client = await pool.connect();
      try {
        const user1 = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user123', 'User 1'],
        );

        const user2 = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user456', 'User 2'],
        );

        expect(user1.rows[0].id).toBeDefined();
        expect(user2.rows[0].id).toBeDefined();
        expect(user1.rows[0].id).not.toEqual(user2.rows[0].id);
      } finally {
        client.release();
      }
    });

    it('should allow NULL email', async () => {
      const client = await pool.connect();
      try {
        const result = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id, email`,
          ['google', 'user123', 'Test User'],
        );

        expect(result.rows[0].email).toBeNull();
      } finally {
        client.release();
      }
    });

    it('should reject invalid provider', async () => {
      const client = await pool.connect();
      try {
        const result = client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3)`,
          ['facebook', 'user123', 'Test User'],
        );

        await expect(result).rejects.toThrow();
      } finally {
        client.release();
      }
    });
  });

  describe('Habits Table Constraints', () => {
    let userId: number;

    beforeEach(async () => {
      const client = await pool.connect();
      try {
        const result = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user123', 'Test User'],
        );
        userId = result.rows[0].id;
      } finally {
        client.release();
      }
    });

    it('should enforce unique habit name per user', async () => {
      const client = await pool.connect();
      try {
        const habit1 = await client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [userId, 'Morning Run', '2026-08-20'],
        );

        expect(habit1.rows[0].id).toBeDefined();

        // Try to insert duplicate habit name
        const duplicate = client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3)`,
          [userId, 'Morning Run', '2026-08-21'],
        );

        await expect(duplicate).rejects.toThrow();
      } finally {
        client.release();
      }
    });

    it('should allow different users to have habit with same name', async () => {
      const client = await pool.connect();
      try {
        // Create second user
        const user2Result = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['github', 'user456', 'Another User'],
        );
        const userId2 = user2Result.rows[0].id;

        const habit1 = await client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [userId, 'Morning Run', '2026-08-20'],
        );

        const habit2 = await client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [userId2, 'Morning Run', '2026-08-20'],
        );

        expect(habit1.rows[0].id).toBeDefined();
        expect(habit2.rows[0].id).toBeDefined();
        expect(habit1.rows[0].id).not.toEqual(habit2.rows[0].id);
      } finally {
        client.release();
      }
    });

    it('should reject start_date in future', async () => {
      const client = await pool.connect();
      try {
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + 1);
        const dateStr = futureDate.toISOString().split('T')[0];

        const result = client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3)`,
          [userId, 'Future Habit', dateStr],
        );

        await expect(result).rejects.toThrow();
      } finally {
        client.release();
      }
    });

    it('should validate habit status enum', async () => {
      const client = await pool.connect();
      try {
        // Valid status
        const habit = await client.query(
          `INSERT INTO habits (user_id, name, start_date, status)
           VALUES ($1, $2, $3, $4) RETURNING id, status`,
          [userId, 'Test Habit', '2026-08-20', 'ACTIVE'],
        );

        expect(habit.rows[0].status).toBe('ACTIVE');

        // Invalid status
        const invalid = client.query(
          `INSERT INTO habits (user_id, name, start_date, status)
           VALUES ($1, $2, $3, $4)`,
          [userId, 'Invalid Habit', '2026-08-20', 'INVALID'],
        );

        await expect(invalid).rejects.toThrow();
      } finally {
        client.release();
      }
    });
  });

  describe('Check-ins Table Constraints', () => {
    let userId: number;
    let habitId: number;

    beforeEach(async () => {
      const client = await pool.connect();
      try {
        // Create user
        const userResult = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user123', 'Test User'],
        );
        userId = userResult.rows[0].id;

        // Create habit
        const habitResult = await client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [userId, 'Morning Run', '2026-08-20'],
        );
        habitId = habitResult.rows[0].id;
      } finally {
        client.release();
      }
    });

    it('should enforce unique check-in per habit per date', async () => {
      const client = await pool.connect();
      try {
        const checkIn1 = await client.query(
          `INSERT INTO check_ins (habit_id, user_id, check_in_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [habitId, userId, '2026-08-20'],
        );

        expect(checkIn1.rows[0].id).toBeDefined();

        // Try to insert duplicate
        const duplicate = client.query(
          `INSERT INTO check_ins (habit_id, user_id, check_in_date)
           VALUES ($1, $2, $3)`,
          [habitId, userId, '2026-08-20'],
        );

        await expect(duplicate).rejects.toThrow();
      } finally {
        client.release();
      }
    });

    it('should allow same habit on different dates', async () => {
      const client = await pool.connect();
      try {
        const checkIn1 = await client.query(
          `INSERT INTO check_ins (habit_id, user_id, check_in_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [habitId, userId, '2026-08-20'],
        );

        const checkIn2 = await client.query(
          `INSERT INTO check_ins (habit_id, user_id, check_in_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [habitId, userId, '2026-08-21'],
        );

        expect(checkIn1.rows[0].id).toBeDefined();
        expect(checkIn2.rows[0].id).toBeDefined();
        expect(checkIn1.rows[0].id).not.toEqual(checkIn2.rows[0].id);
      } finally {
        client.release();
      }
    });

    it('should reject check_in_date in future', async () => {
      const client = await pool.connect();
      try {
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + 1);
        const dateStr = futureDate.toISOString().split('T')[0];

        const result = client.query(
          `INSERT INTO check_ins (habit_id, user_id, check_in_date)
           VALUES ($1, $2, $3)`,
          [habitId, userId, dateStr],
        );

        await expect(result).rejects.toThrow();
      } finally {
        client.release();
      }
    });
  });

  describe('Milestone Notifications Table Constraints', () => {
    let userId: number;
    let habitId: number;

    beforeEach(async () => {
      const client = await pool.connect();
      try {
        // Create user
        const userResult = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user123', 'Test User'],
        );
        userId = userResult.rows[0].id;

        // Create habit
        const habitResult = await client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3) RETURNING id`,
          [userId, 'Morning Run', '2026-08-20'],
        );
        habitId = habitResult.rows[0].id;
      } finally {
        client.release();
      }
    });

    it('should only allow milestone values 3, 7, 30', async () => {
      const client = await pool.connect();
      try {
        // Valid milestone
        const notification = await client.query(
          `INSERT INTO milestone_notifications (habit_id, user_id, milestone)
           VALUES ($1, $2, $3) RETURNING id, milestone`,
          [habitId, userId, 7],
        );

        expect(notification.rows[0].milestone).toBe(7);

        // Invalid milestone
        const invalid = client.query(
          `INSERT INTO milestone_notifications (habit_id, user_id, milestone)
           VALUES ($1, $2, $3)`,
          [habitId, userId, 5],
        );

        await expect(invalid).rejects.toThrow();
      } finally {
        client.release();
      }
    });

    it('should enforce unique milestone per habit', async () => {
      const client = await pool.connect();
      try {
        const notification1 = await client.query(
          `INSERT INTO milestone_notifications (habit_id, user_id, milestone)
           VALUES ($1, $2, $3) RETURNING id`,
          [habitId, userId, 7],
        );

        expect(notification1.rows[0].id).toBeDefined();

        // Try to insert duplicate
        const duplicate = client.query(
          `INSERT INTO milestone_notifications (habit_id, user_id, milestone)
           VALUES ($1, $2, $3)`,
          [habitId, userId, 7],
        );

        await expect(duplicate).rejects.toThrow();
      } finally {
        client.release();
      }
    });

    it('should allow different milestones for same habit', async () => {
      const client = await pool.connect();
      try {
        const notification1 = await client.query(
          `INSERT INTO milestone_notifications (habit_id, user_id, milestone)
           VALUES ($1, $2, $3) RETURNING id`,
          [habitId, userId, 3],
        );

        const notification2 = await client.query(
          `INSERT INTO milestone_notifications (habit_id, user_id, milestone)
           VALUES ($1, $2, $3) RETURNING id`,
          [habitId, userId, 7],
        );

        expect(notification1.rows[0].id).toBeDefined();
        expect(notification2.rows[0].id).toBeDefined();
        expect(notification1.rows[0].id).not.toEqual(notification2.rows[0].id);
      } finally {
        client.release();
      }
    });
  });

  describe('Foreign Key Constraints', () => {
    it('should cascade delete habits when user is deleted', async () => {
      const client = await pool.connect();
      try {
        // Create user
        const userResult = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user123', 'Test User'],
        );
        const userId = userResult.rows[0].id;

        // Create habit
        await client.query(
          `INSERT INTO habits (user_id, name, start_date)
           VALUES ($1, $2, $3)`,
          [userId, 'Morning Run', '2026-08-20'],
        );

        // Delete user
        await client.query(`DELETE FROM users WHERE id = $1`, [userId]);

        // Check habits are deleted
        const habits = await client.query(
          `SELECT COUNT(*) as count FROM habits WHERE user_id = $1`,
          [userId],
        );

        expect(habits.rows[0].count).toBe('0');
      } finally {
        client.release();
      }
    });

    it('should reject check-in with non-existent habit', async () => {
      const client = await pool.connect();
      try {
        // Create user
        const userResult = await client.query(
          `INSERT INTO users (provider, provider_user_id, display_name)
           VALUES ($1, $2, $3) RETURNING id`,
          ['google', 'user123', 'Test User'],
        );
        const userId = userResult.rows[0].id;

        // Try to create check-in with non-existent habit
        const result = client.query(
          `INSERT INTO check_ins (habit_id, user_id, check_in_date)
           VALUES ($1, $2, $3)`,
          [99999, userId, '2026-08-20'],
        );

        await expect(result).rejects.toThrow();
      } finally {
        client.release();
      }
    });
  });
});
