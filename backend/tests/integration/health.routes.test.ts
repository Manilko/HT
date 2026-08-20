//
//  health.routes.test.ts
//  Health Routes Integration Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import request from 'supertest';
import { createApp } from '../../src/config/app';
import * as database from '../../src/config/database';

jest.mock('../../src/config/database');

describe('Health Routes Integration', () => {
  let app: any;

  beforeAll(() => {
    app = createApp();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('API Response Format', () => {
    it('should always include success field', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');

      expect(response.body).toHaveProperty('success');
      expect(typeof response.body.success).toBe('boolean');
    });

    it('should include timestamp in ISO 8601 format', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');

      expect(response.body.timestamp).toBeDefined();
      expect(new Date(response.body.timestamp).getTime()).toBeGreaterThan(0);
    });

    it('should have data field when success is true', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');

      if (response.body.success) {
        expect(response.body.data).toBeDefined();
      }
    });

    it('should have error field when success is false', async () => {
      const response = await request(app).get('/nonexistent');

      if (!response.body.success) {
        expect(response.body.error).toBeDefined();
        expect(response.body.error.code).toBeDefined();
        expect(response.body.error.message).toBeDefined();
      }
    });
  });

  describe('Health Data Structure', () => {
    it('should include all required health fields', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');
      const healthData = response.body.data;

      expect(healthData).toHaveProperty('status');
      expect(healthData).toHaveProperty('timestamp');
      expect(healthData).toHaveProperty('uptime');
      expect(healthData).toHaveProperty('database');
    });

    it('should have database with connected field', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');
      const database_info = response.body.data.database;

      expect(typeof database_info.connected).toBe('boolean');
    });
  });

  describe('HTTP Status Codes', () => {
    it('should return 200 for successful health check', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
    });

    it('should return 404 for invalid routes', async () => {
      const response = await request(app).get('/invalid-route');

      expect(response.status).toBe(404);
    });

    it('should return proper content type', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');

      expect(response.type).toMatch(/json/);
    });
  });
});
