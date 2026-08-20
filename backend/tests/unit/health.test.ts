//
//  health.test.ts
//  Health Endpoint Tests
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import request from 'supertest';
import { createApp } from '../../src/config/app';
import * as database from '../../src/config/database';

jest.mock('../../src/config/database');

describe('Health Endpoint', () => {
  let app: any;

  beforeAll(() => {
    app = createApp();
  });

  describe('GET /health', () => {
    it('should return 200 with success response', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
      expect(response.body.timestamp).toBeDefined();
    });

    it('should include status, uptime, and database fields', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');

      expect(response.body.data.status).toBe('ok');
      expect(typeof response.body.data.uptime).toBe('number');
      expect(response.body.data.uptime).toBeGreaterThan(0);
      expect(response.body.data.database).toBeDefined();
      expect(response.body.data.database.connected).toBe(true);
    });

    it('should report database not connected on query failure', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockRejectedValue(new Error('DB connection failed')),
      });

      const response = await request(app).get('/health');

      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.database.connected).toBe(false);
    });

    it('should include ISO timestamp in response', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response = await request(app).get('/health');
      const timestamp = response.body.timestamp;

      expect(timestamp).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
    });

    it('should return consistent responses on multiple calls', async () => {
      (database.getPool as jest.Mock).mockReturnValue({
        query: jest.fn().mockResolvedValue({ rows: [{ now: new Date() }] }),
      });

      const response1 = await request(app).get('/health');
      const response2 = await request(app).get('/health');

      expect(response1.body.success).toBe(response2.body.success);
      expect(response1.body.data.status).toBe(response2.body.data.status);
    });
  });

  describe('Error Responses', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app).get('/nonexistent');

      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBeDefined();
      expect(response.body.error.code).toBe('NOT_FOUND');
    });
  });
});
