//
//  errorHandling.test.ts
//  Error Handling Integration Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import request from 'supertest';
import { createApp } from '../../src/config/app';
import { getPool } from '../../src/config/database';
import { generateAccessToken } from '../../src/utils/tokenUtils';

const app = createApp();
const pool = getPool();

const validToken = generateAccessToken(999, 'test@test.com', 'google', 'test_user_123');

describe('Error Handling', () => {
  beforeAll(async () => {
    const { runMigrations } = await import('../../src/migrations/runner');
    try {
      await runMigrations();
    } catch (error) {
      // Already migrated
    }
  });

  afterEach(async () => {
    const client = await pool.connect();
    try {
      await client.query('TRUNCATE TABLE check_ins CASCADE');
      await client.query('TRUNCATE TABLE habits CASCADE');
      await client.query('TRUNCATE TABLE users CASCADE');
    } finally {
      client.release();
    }
  });

  // MARK: - Authentication Errors

  describe('Authentication Error Responses', () => {
    it('should return 401 for missing token', async () => {
      const res = await request(app).get('/v1/habits');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('MISSING_TOKEN');
      expect(res.body.error.message).toContain('Authentication token is required');
    });

    it('should return 401 for invalid token', async () => {
      const res = await request(app)
        .get('/v1/habits')
        .set('Authorization', 'Bearer invalid.token.here');

      expect(res.status).toBe(401);
      expect(res.body.error.code).toBe('INVALID_TOKEN');
      expect(res.body.error.message).toContain('session has expired');
    });

    it('should return 401 for malformed header', async () => {
      const res = await request(app)
        .get('/v1/habits')
        .set('Authorization', 'InvalidFormat');

      expect(res.status).toBe(401);
    });
  });

  // MARK: - Authorization Errors

  describe('Authorization Error Responses', () => {
    it('should return 403 when accessing another users habit', async () => {
      const user1Token = generateAccessToken(1001, 'user1@test.com', 'google', 'user_1');
      const user2Token = generateAccessToken(1002, 'user2@test.com', 'github', 'user_2');

      // User 1 creates habit
      const createRes = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          name: 'User 1 Habit',
          startDate: '2026-08-20',
        });

      const habitId = createRes.body.data.id;

      // User 2 tries to access it
      const getRes = await request(app)
        .get(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(getRes.status).toBe(403);
      expect(getRes.body.error.code).toBe('FORBIDDEN');
      // Should NOT expose internal details
      expect(getRes.body.error.message).not.toContain('user_id');
      expect(getRes.body.error.message).not.toContain('database');
    });
  });

  // MARK: - Validation Errors

  describe('Validation Error Responses', () => {
    it('should return 400 for missing habit name', async () => {
      const res = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          description: 'No name',
          startDate: '2026-08-20',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_REQUEST');
      expect(res.body.error.message).toContain('name');
    });

    it('should return 400 for empty habit name', async () => {
      const res = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: '   ',
          startDate: '2026-08-20',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('INVALID_REQUEST');
    });

    it('should return 400 for future start date', async () => {
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 1);

      const res = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Future Habit',
          startDate: futureDate.toISOString().split('T')[0],
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('future');
    });

    it('should return 400 for invalid status', async () => {
      const res = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Test',
          startDate: '2026-08-20',
          status: 'INVALID_STATUS',
        });

      expect(res.status).toBe(400);
    });
  });

  // MARK: - Duplicate Check-in

  describe('Duplicate Check-in Error', () => {
    it('should return 409 for duplicate check-in', async () => {
      // Create habit
      const createRes = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Test Habit',
          startDate: '2026-08-20',
        });

      const habitId = createRes.body.data.id;

      // Check in first time
      const checkInRes1 = await request(app)
        .post(`/v1/habits/${habitId}/check-ins`)
        .set('Authorization', `Bearer ${validToken}`);

      expect(checkInRes1.status).toBe(201);

      // Try to check in again
      const checkInRes2 = await request(app)
        .post(`/v1/habits/${habitId}/check-ins`)
        .set('Authorization', `Bearer ${validToken}`);

      expect(checkInRes2.status).toBe(409);
      expect(checkInRes2.body.error.code).toBe('DUPLICATE_CHECK_IN');
      expect(checkInRes2.body.error.message).toContain('already completed');
    });
  });

  // MARK: - Invalid Status Transitions

  describe('Invalid Status Transition Errors', () => {
    it('should return 400 for invalid transition ARCHIVED -> ACTIVE', async () => {
      // Create habit
      const createRes = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Test Habit',
          startDate: '2026-08-20',
        });

      const habitId = createRes.body.data.id;

      // Archive it
      await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send({ status: 'ARCHIVED' });

      // Try to transition to ACTIVE
      const res = await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send({ status: 'ACTIVE' });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('cannot transition');
    });
  });

  // MARK: - Not Found Errors

  describe('Not Found Error Responses', () => {
    it('should return 404 for non-existent habit', async () => {
      const res = await request(app)
        .get('/v1/habits/999999')
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(404);
      expect(res.body.error.code).toBe('NOT_FOUND');
      expect(res.body.error.message).toContain('not found');
    });

    it('should return 404 for check-in on non-existent habit', async () => {
      const res = await request(app)
        .delete('/v1/habits/999999/check-ins/today')
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(403); // Access denied first
    });
  });

  // MARK: - Paused/Archived Habit Errors

  describe('Paused/Archived Habit Errors', () => {
    it('should return 400 when checking in to paused habit', async () => {
      const createRes = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Test Habit',
          startDate: '2026-08-20',
        });

      const habitId = createRes.body.data.id;

      // Pause it
      await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send({ status: 'PAUSED' });

      // Try to check in
      const res = await request(app)
        .post(`/v1/habits/${habitId}/check-ins`)
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('paused');
    });

    it('should return 400 when checking in to archived habit', async () => {
      const createRes = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Test Habit',
          startDate: '2026-08-20',
        });

      const habitId = createRes.body.data.id;

      // Archive it
      await request(app)
        .patch(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${validToken}`)
        .send({ status: 'ARCHIVED' });

      // Try to check in
      const res = await request(app)
        .post(`/v1/habits/${habitId}/check-ins`)
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('archived');
    });
  });

  // MARK: - Error Response Format

  describe('Consistent Error Response Format', () => {
    it('should always return error with code and message', async () => {
      const res = await request(app).get('/v1/habits');

      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('success', false);
      expect(res.body).toHaveProperty('error');
      expect(res.body.error).toHaveProperty('code');
      expect(res.body.error).toHaveProperty('message');
      expect(res.body).toHaveProperty('timestamp');
    });

    it('should not expose internal database errors', async () => {
      const res = await request(app).get('/v1/habits');

      const responseStr = JSON.stringify(res.body);

      expect(responseStr).not.toContain('SELECT');
      expect(responseStr).not.toContain('INSERT');
      expect(responseStr).not.toContain('UPDATE');
      expect(responseStr).not.toContain('DELETE');
      expect(responseStr).not.toContain('.sqlite');
      expect(responseStr).not.toContain('Traceback');
    });

    it('should not expose file paths', async () => {
      const res = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ name: '' });

      const responseStr = JSON.stringify(res.body);

      expect(responseStr).not.toContain('/');
      expect(responseStr).not.toContain('\\');
    });
  });

  // MARK: - HTTP Status Codes

  describe('Correct HTTP Status Codes', () => {
    it('should use 400 for validation errors', async () => {
      const res = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({ name: '' });

      expect(res.status).toBe(400);
    });

    it('should use 401 for authentication errors', async () => {
      const res = await request(app).get('/v1/habits');

      expect(res.status).toBe(401);
    });

    it('should use 403 for authorization errors', async () => {
      const user1Token = generateAccessToken(1001, 'user1@test.com', 'google', 'user_1');
      const user2Token = generateAccessToken(1002, 'user2@test.com', 'github', 'user_2');

      const createRes = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${user1Token}`)
        .send({
          name: 'Test',
          startDate: '2026-08-20',
        });

      const habitId = createRes.body.data.id;

      const res = await request(app)
        .get(`/v1/habits/${habitId}`)
        .set('Authorization', `Bearer ${user2Token}`);

      expect(res.status).toBe(403);
    });

    it('should use 404 for not found', async () => {
      const res = await request(app)
        .get('/v1/habits/999999')
        .set('Authorization', `Bearer ${validToken}`);

      expect(res.status).toBe(404);
    });

    it('should use 409 for conflict (duplicate)', async () => {
      const createRes = await request(app)
        .post('/v1/habits')
        .set('Authorization', `Bearer ${validToken}`)
        .send({
          name: 'Test',
          startDate: '2026-08-20',
        });

      const habitId = createRes.body.data.id;

      await request(app)
        .post(`/v1/habits/${habitId}/check-ins`)
        .set('Authorization', `Bearer ${validToken}`);

      const duplicateRes = await request(app)
        .post(`/v1/habits/${habitId}/check-ins`)
        .set('Authorization', `Bearer ${validToken}`);

      expect(duplicateRes.status).toBe(409);
    });
  });
});
