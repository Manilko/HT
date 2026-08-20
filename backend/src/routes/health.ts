//
//  health.ts
//  Habit Tracker Backend
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Router, Request, Response } from 'express';
import { asyncHandler, ApiResponse } from '../middleware/errorHandler';
import { getPool } from '../config/database';

interface HealthResponse {
  status: string;
  timestamp: string;
  uptime: number;
  database: {
    connected: boolean;
  };
}

export function createHealthRouter(): Router {
  const router = Router();

  router.get(
    '/',
    asyncHandler(async (req: Request, res: Response) => {
      const pool = getPool();
      let dbConnected = false;

      try {
        const result = await pool.query('SELECT NOW()');
        dbConnected = !!result.rows;
      } catch (error) {
        dbConnected = false;
      }

      const response: ApiResponse<HealthResponse> = {
        success: true,
        data: {
          status: 'ok',
          timestamp: new Date().toISOString(),
          uptime: process.uptime(),
          database: {
            connected: dbConnected,
          },
        },
        timestamp: new Date().toISOString(),
      };

      res.json(response);
    }),
  );

  return router;
}
