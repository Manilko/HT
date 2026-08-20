//
//  habits.routes.test.ts
//  Habits Routes Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import request from 'supertest';
import { createApp } from '../../src/config/app';
import { getPool } from '../../src/config/database';
import { generateAccessToken } from '../../src/utils/tokenUtils';

const app = createApp();
const pool = getPool();

describe('Habits Routes', () => {
  let user1Id: number;
  let user2Id: number;
  let user1Token: string;
  let user2Token: string;
  let habitId: number;

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

  describe('GET /v1/habits - List habits', () => {
    it('should return 401 without authentication token', async () => {
      const response = await request(app).get('/v1/habits');
      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
    });

    it('should return empty array for user with no habits', async () => {
      const response = await request(app)
        .get('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.habits).toEqual([]);
      expect(response.body.data.count).toBe(0);
    });

    it('should return user habits only', async () => {
      await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'User1 Habit', startDate: '2026-08-20' });

      await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user2Token}`)
        .send({ name: 'User2 Habit', startDate: '2026-08-20' });

      const response = await request(app)
        .get('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(200);
      expect(response.body.data.habits).toHaveLength(1);
      expect(response.body.data.habits[0].name).toBe('User1 Habit');
    });
  });

  describe('GET /v1/habits/:id - Get single habit', () => {
    beforeEach(async () => {
      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Test Habit', description: 'Test Description', startDate: '2026-08-20' });
      habitId = response.body.data.id;
    });

    it('should return habit details', async () => {
      const response = await request(app)
        .get(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(200);
      expect(response.body.data.name).toBe('Test Habit');
      expect(response.body.data.description).toBe('Test Description');
      expect(response.body.data.status).toBe('ACTIVE');
    });

    it('should return 403 for other users habit', async () => {
      const response = await request(app)
        .get(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(response.status).toBe(403);
      expect(response.body.error.code).toBe('FORBIDDEN');
    });

    it('should return 404 for non-existent habit', async () => {
      const response = await request(app)
        .get('/v1/habits/99999')
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(404);
    });
  });

  describe('POST /v1/habits - Create habit', () => {
    it('should create habit with required fields', async () => {
      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Morning Run', startDate: '2026-08-20' });

      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Morning Run');
      expect(response.body.data.status).toBe('ACTIVE');
    });

    it('should return 400 if name is missing', async () => {
      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ startDate: '2026-08-20' });

      expect(response.status).toBe(400);
    });

    it('should return 400 if start date is in future', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 1);
      const dateStr = futureDate.toISOString().split('T')[0];

      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Future Habit', startDate: dateStr });

      expect(response.status).toBe(400);
    });

    it('should enforce unique habit name per user', async () => {
      await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Morning Run', startDate: '2026-08-20' });

      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Morning Run', startDate: '2026-08-20' });

      expect(response.status).toBe(400);
    });
  });

  describe('PATCH /v1/habits/:id - Update habit', () => {
    beforeEach(async () => {
      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Morning Run', description: 'Original', startDate: '2026-08-20' });
      habitId = response.body.data.id;
    });

    it('should update habit name', async () => {
      const response = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Evening Run' });

      expect(response.status).toBe(200);
      expect(response.body.data.name).toBe('Evening Run');
    });

    it('should update habit status', async () => {
      const response = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'PAUSED' });

      expect(response.status).toBe(200);
      expect(response.body.data.status).toBe('PAUSED');
    });

    it('should return 403 for other users habit', async () => {
      const response = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user2Token}`)
        .send({ name: 'Hacked' });

      expect(response.status).toBe(403);
    });
  });

  describe('Status Transitions', () => {
    beforeEach(async () => {
      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Test Habit', startDate: '2026-08-20' });
      habitId = response.body.data.id;
    });

    it('should allow ACTIVE to PAUSED transition', async () => {
      const response = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'PAUSED' });

      expect(response.status).toBe(200);
      expect(response.body.data.status).toBe('PAUSED');
    });

    it('should allow ACTIVE to ARCHIVED transition', async () => {
      const response = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'ARCHIVED' });

      expect(response.status).toBe(200);
      expect(response.body.data.status).toBe('ARCHIVED');
    });

    it('should reject ARCHIVED to ACTIVE transition', async () => {
      await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'ARCHIVED' });

      const response = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'ACTIVE' });

      expect(response.status).toBe(400);
    });
  });

  describe('Archived Habit Rules', () => {
    beforeEach(async () => {
      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Test Habit', startDate: '2026-08-20' });
      habitId = response.body.data.id;

      await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'ARCHIVED' });
    });

    it('should prevent modification of archived habit name', async () => {
      const response = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Modified Name' });

      expect(response.status).toBe(400);
    });
  });

  describe('DELETE /v1/habits/:id - Delete habit', () => {
    beforeEach(async () => {
      const response = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ name: 'Test Habit', startDate: '2026-08-20' });
      habitId = response.body.data.id;
    });

    it('should require habit to be archived before deletion', async () => {
      const response = await request(app)
        .delete(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(400);
      expect(response.body.error.code).toBe('INVALID_REQUEST');
    });

    it('should delete archived habit', async () => {
      await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'ARCHIVED' });

      const response = await request(app)
        .delete(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`);

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });

    it('should return 403 for other users habit', async () => {
      await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user1Token}`)
        .send({ status: 'ARCHIVED' });

      const response = await request(app)
        .delete(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(response.status).toBe(403);
    });
  });
});
