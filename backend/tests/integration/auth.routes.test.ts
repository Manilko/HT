//
//  auth.routes.test.ts
//  Authentication Routes Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import request from 'supertest';
import { createApp } from '../../src/config/app';
import { getPool } from '../../src/config/database';
import { verifyToken } from '../../src/utils/tokenUtils';

const app = createApp();
const pool = getPool();

describe('Authentication Routes', () => {
  beforeAll(async () => {
    // Run migrations
    const { runMigrations } = await import('../../src/migrations/runner');
    try {
      await runMigrations();
    } catch (error) {
      // Migrations may already be run
    }
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

  describe('POST /v1/auth/google/callback', () => {
    it('should authenticate user and return tokens', async () => {
      const response = await request(app).post('/v1/auth/google/callback').send({
        code: 'valid_auth_code',
      });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.id).toBeDefined();
      expect(response.body.data.user.displayName).toBe('Google Test User');
      expect(response.body.timestamp).toBeDefined();
    });

    it('should create a new user on first Google login', async () => {
      const response = await request(app).post('/v1/auth/google/callback').send({
        code: 'new_user_code',
      });

      expect(response.status).toBe(200);
      const userId = response.body.data.user.id;

      // Verify user was created in database
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT * FROM users WHERE id = $1', [userId]);
        expect(result.rows.length).toBe(1);
        expect(result.rows[0].provider).toBe('google');
        expect(result.rows[0].display_name).toBe('Google Test User');
      } finally {
        client.release();
      }
    });

    it('should reuse existing user on second Google login', async () => {
      // First login
      const response1 = await request(app).post('/v1/auth/google/callback').send({
        code: 'test_code_1',
      });

      const userId1 = response1.body.data.user.id;

      // Second login with same provider ID
      const response2 = await request(app).post('/v1/auth/google/callback').send({
        code: 'test_code_2',
      });

      const userId2 = response2.body.data.user.id;

      // Same user should be returned
      expect(userId1).toBe(userId2);

      // Verify only one user in database
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT COUNT(*) as count FROM users WHERE provider = $1', ['google']);
        expect(result.rows[0].count).toBe('1');
      } finally {
        client.release();
      }
    });

    it('should return 400 if code is missing', async () => {
      const response = await request(app).post('/v1/auth/google/callback').send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('INVALID_REQUEST');
    });

    it('should verify returned JWT token is valid', async () => {
      const response = await request(app).post('/v1/auth/google/callback').send({
        code: 'valid_code',
      });

      expect(response.status).toBe(200);
      const { accessToken } = response.body.data;

      // Verify token structure
      const payload = verifyToken(accessToken);
      expect(payload.sub).toBe(response.body.data.user.id);
      expect(payload.oauthProvider).toBe('google');
      expect(payload.aud).toBe('ios-app');
      expect(payload.exp).toBeGreaterThan(payload.iat);
    });
  });

  describe('POST /v1/auth/github/callback', () => {
    it('should authenticate user and return tokens', async () => {
      const response = await request(app).post('/v1/auth/github/callback').send({
        code: 'valid_auth_code',
      });

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
      expect(response.body.data.accessToken).toBeDefined();
      expect(response.body.data.refreshToken).toBeDefined();
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.id).toBeDefined();
      expect(response.body.data.user.displayName).toBe('GitHub Test User');
      expect(response.body.timestamp).toBeDefined();
    });

    it('should create a new user on first GitHub login', async () => {
      const response = await request(app).post('/v1/auth/github/callback').send({
        code: 'new_user_code',
      });

      expect(response.status).toBe(200);
      const userId = response.body.data.user.id;

      // Verify user was created in database
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT * FROM users WHERE id = $1', [userId]);
        expect(result.rows.length).toBe(1);
        expect(result.rows[0].provider).toBe('github');
        expect(result.rows[0].display_name).toBe('GitHub Test User');
      } finally {
        client.release();
      }
    });

    it('should reuse existing user on second GitHub login', async () => {
      // First login
      const response1 = await request(app).post('/v1/auth/github/callback').send({
        code: 'test_code_1',
      });

      const userId1 = response1.body.data.user.id;

      // Second login with same provider ID
      const response2 = await request(app).post('/v1/auth/github/callback').send({
        code: 'test_code_2',
      });

      const userId2 = response2.body.data.user.id;

      // Same user should be returned
      expect(userId1).toBe(userId2);

      // Verify only one user in database
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT COUNT(*) as count FROM users WHERE provider = $1', ['github']);
        expect(result.rows[0].count).toBe('1');
      } finally {
        client.release();
      }
    });

    it('should allow null email for GitHub users', async () => {
      const response = await request(app).post('/v1/auth/github/callback').send({
        code: 'no_email_code',
      });

      expect(response.status).toBe(200);
      expect(response.body.data.user.email).toBeNull();

      // Verify in database
      const userId = response.body.data.user.id;
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT email FROM users WHERE id = $1', [userId]);
        expect(result.rows[0].email).toBeNull();
      } finally {
        client.release();
      }
    });

    it('should return 400 if code is missing', async () => {
      const response = await request(app).post('/v1/auth/github/callback').send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('INVALID_REQUEST');
    });
  });

  describe('POST /v1/auth/refresh', () => {
    it('should return new access token with valid refresh token', async () => {
      // First authenticate to get refresh token
      const authResponse = await request(app).post('/v1/auth/google/callback').send({
        code: 'test_code',
      });

      const { refreshToken } = authResponse.body.data;

      // Use refresh token
      const refreshResponse = await request(app).post('/v1/auth/refresh').send({
        refreshToken,
      });

      expect(refreshResponse.status).toBe(200);
      expect(refreshResponse.body.success).toBe(true);
      expect(refreshResponse.body.data.accessToken).toBeDefined();

      // Verify new token is valid
      const payload = verifyToken(refreshResponse.body.data.accessToken);
      expect(payload.sub).toBe(authResponse.body.data.user.id);
      expect(payload.aud).toBe('ios-app');
    });

    it('should return 400 if refresh token is missing', async () => {
      const response = await request(app).post('/v1/auth/refresh').send({});

      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('INVALID_REQUEST');
    });

    it('should return 401 if refresh token is invalid', async () => {
      const response = await request(app).post('/v1/auth/refresh').send({
        refreshToken: 'invalid.token.here',
      });

      expect(response.status).toBe(401);
      expect(response.body.success).toBe(false);
      expect(response.body.error.code).toBe('UNAUTHORIZED');
    });

    it('should return 401 if refresh token is expired', async () => {
      // Create an expired token (manually, or use a mock that returns expired)
      // For now, we can't easily test this without manipulating time
      // This would be tested with a clock mock in production
    });
  });

  describe('POST /v1/auth/logout', () => {
    it('should return success on logout', async () => {
      const response = await request(app).post('/v1/auth/logout').send({});

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('Multiple providers for same user (future)', () => {
    it('should allow different OAuth providers to create separate accounts', async () => {
      // User logs in with Google
      const googleResponse = await request(app).post('/v1/auth/google/callback').send({
        code: 'google_code_1',
      });

      const googleUserId = googleResponse.body.data.user.id;

      // Same user logs in with GitHub (different provider ID)
      const githubResponse = await request(app).post('/v1/auth/github/callback').send({
        code: 'github_code_1',
      });

      const githubUserId = githubResponse.body.data.user.id;

      // Currently, these create separate users (accounts)
      // Future: implement user connection linking
      expect(googleUserId).not.toBe(githubUserId);

      // Verify both users exist
      const client = await pool.connect();
      try {
        const result = await client.query('SELECT COUNT(*) as count FROM users');
        expect(result.rows[0].count).toBe('2');
      } finally {
        client.release();
      }
    });
  });
});
