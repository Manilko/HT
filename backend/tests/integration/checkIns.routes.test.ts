//
//  checkIns.routes.test.ts
//  Check-ins Routes Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import request from 'supertest';
import { createApp } from '../../src/config/app';
import { getPool } from '../../src/config/database';
import { generateAccessToken } from '../../src/utils/tokenUtils';

const app = createApp();
const pool = getPool();

describe('Check-ins Routes', () => {
  let user1Id: number;
  let user2Id: number;
  let user1Token: string;
  let user2Token: string;
  let activeHabitId: number;
  let pausedHabitId: number;
  let archivedHabitId: number;

  beforeAll(async () => {
    // Run migrations
    const { runMigrations } = await import('../../src/migrations/runner');
    try {
      await runMigrations();
    } catch (error) {
      // Migrations may already be run
    }
  });

  beforeEach(async () => {
    // Create test users
    const client = await pool.connect();
    try {
      const user1Result = await client.query(
        `INSERT INTO users (provider, provider_user_id, display_name, created_at, updated_at)
         VALUES ('test', 'user1', 'Test User 1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         RETURNING id`,
      );
      user1Id = user1Result.rows[0].id;

      const user2Result = await client.query(
        `INSERT INTO users (provider, provider_user_id, display_name, created_at, updated_at)
         VALUES ('test', 'user2', 'Test User 2', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         RETURNING id`,
      );
      user2Id = user2Result.rows[0].id;

      // Create active habit
      const activeResult = await client.query(
        `INSERT INTO habits (user_id, name, start_date, status, created_at, updated_at)
         VALUES ($1, 'Active Habit', CURRENT_DATE, 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         RETURNING id`,
        [user1Id],
      );
      activeHabitId = activeResult.rows[0].id;

      // Create paused habit
      const pausedResult = await client.query(
        `INSERT INTO habits (user_id, name, start_date, status, created_at, updated_at)
         VALUES ($1, 'Paused Habit', CURRENT_DATE, 'PAUSED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         RETURNING id`,
        [user1Id],
      );
      pausedHabitId = pausedResult.rows[0].id;

      // Create archived habit
      const archivedResult = await client.query(
        `INSERT INTO habits (user_id, name, start_date, status, created_at, updated_at)
         VALUES ($1, 'Archived Habit', CURRENT_DATE, 'ARCHIVED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
         RETURNING id`,
        [user1Id],
      );
      archivedHabitId = archivedResult.rows[0].id;
    } finally {
      client.release();
    }

    // Generate tokens
    user1Token = generateAccessToken(user1Id, 'user1@test.com', 'test', 'user1');
    user2Token = generateAccessToken(user2Id, 'user2@test.com', 'test', 'user2');
  });

  afterEach(async () => {
    // Clean up test data
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

  describe('POST /v1/habits/:habitId/check-ins - Create today\'s check-in', () => {
    it('should create check-in for today', async () => {
      const response = await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.habitId).toBe(activeHabitId);
      expect(response.body.data.userId).toBe(user1Id);
    });

    it('should return 401 without authentication token', async () => {
      const response = await request(app).post(`/v1/habits/${activeHabitId}/check-ins`);

      expect(response.status).toBe(401);
      expect(response.body.error.code).toBe('UNAUTHORIZED');
    });

    it('should reject duplicate check-in for today', async () => {
      // Create first check-in
      await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      // Try to create duplicate
      const response = await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(409);
      expect(response.body.error.code).toBe('INVALID_REQUEST');
    });

    it('should reject check-in for paused habit', async () => {
      const response = await request(app)
        .post(`/v1/habits/${pausedHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(400);
      expect(response.body.error.message).toContain('paused');
    });

    it('should reject check-in for archived habit', async () => {
      const response = await request(app)
        .post(`/v1/habits/${archivedHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(400);
      expect(response.body.error.message).toContain('archived');
    });

    it('should return 403 for other users habit', async () => {
      const response = await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });

    it('should return 400 for invalid habit ID', async () => {
      const response = await request(app)
        .post('/v1/habits/invalid/check-ins')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(400);
    });
  });

  describe('GET /v1/habits/:habitId/check-ins - Get all check-ins', () => {
    it('should return empty check-ins for new habit', async () => {
      const response = await request(app)
        .get(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(200);
      expect(response.body.data.checkIns).toEqual([]);
      expect(response.body.data.count).toBe(0);
    });

    it('should return check-ins for habit', async () => {
      // Create check-in
      await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      const response = await request(app)
        .get(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(200);
      expect(response.body.data.checkIns).toHaveLength(1);
      expect(response.body.data.count).toBe(1);
    });

    it('should return 403 for other users habit', async () => {
      const response = await request(app)
        .get(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(response.status).toBe(403);
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app).get(`/v1/habits/${activeHabitId}/check-ins`);

      expect(response.status).toBe(401);
    });
  });

  describe('DELETE /v1/habits/:habitId/check-ins/today - Undo today\'s check-in', () => {
    beforeEach(async () => {
      // Create a check-in first
      await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);
    });

    it('should delete todays check-in', async () => {
      const response = await request(app)
        .delete(`/v1/habits/${activeHabitId}/check-ins/today`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it('should prevent checking in twice after undo', async () => {
      // Delete today's check-in
      await request(app)
        .delete(`/v1/habits/${activeHabitId}/check-ins/today`)
        .set('Authorization', `Bearer ${user1Token}`);

      // Create new check-in
      const response = await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(201);
    });

    it('should return 404 when no check-in for today', async () => {
      // Delete first
      await request(app)
        .delete(`/v1/habits/${activeHabitId}/check-ins/today`)
        .set('Authorization', `Bearer ${user1Token}`);

      // Try to delete again
      const response = await request(app)
        .delete(`/v1/habits/${activeHabitId}/check-ins/today`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(404);
      expect(response.body.error.code).toBe('NOT_FOUND');
    });

    it('should return 403 for other users check-in', async () => {
      const response = await request(app)
        .delete(`/v1/habits/${activeHabitId}/check-ins/today`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });

    it('should return 401 without authentication', async () => {
      const response = await request(app).delete(`/v1/habits/${activeHabitId}/check-ins/today`);

      expect(response.status).toBe(401);
    });
  });

  describe('Authorization and Edge Cases', () => {
    it('should maintain user isolation across check-ins', async () => {
      // User 1 creates check-in
      await request(app)
        .post(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user1Token}`);

      // User 2 cannot see it
      const response = await request(app)
        .get(`/v1/habits/${activeHabitId}/check-ins`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(response.status).toBe(403);
    });

    it('should handle multiple check-ins on same habit', async () => {
      // Create active habits for user 1
      const client = await pool.connect();
      try {
        const result = await client.query(
          `INSERT INTO habits (user_id, name, start_date, status, created_at, updated_at)
           VALUES ($1, 'Second Habit', CURRENT_DATE, 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
           RETURNING id`,
          [user1Id],
        );
        const secondHabitId = result.rows[0].id;

        // Create check-in for first habit
        await request(app)
          .post(`/v1/habits/${activeHabitId}/check-ins`)
          .set('Authorization', `Bearer ${user1Token}`);

        // Create check-in for second habit
        await request(app)
          .post(`/v1/habits/${secondHabitId}/check-ins`)
          .set('Authorization', `Bearer ${user1Token}`);

        // Get check-ins for first habit
        const response1 = await request(app)
          .get(`/v1/habits/${activeHabitId}/check-ins`)
          .set('Authorization', `Bearer ${user1Token}`);

        expect(response1.body.data.count).toBe(1);

        // Get check-ins for second habit
        const response2 = await request(app)
          .get(`/v1/habits/${secondHabitId}/check-ins`)
          .set('Authorization', `Bearer ${user1Token}`);

        expect(response2.body.data.count).toBe(1);
      } finally {
        client.release();
      }
    });
  });
});
