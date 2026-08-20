//
//  app.ts
//  Habit Tracker Backend
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './env';
import { logger } from './logger';
import { errorHandler, AppError } from '../middleware/errorHandler';
import { requestLogger } from '../middleware/requestLogger';
import { createHealthRouter } from '../routes/health';

export function createApp(): express.Application {
  const app = express();

  // Trust proxy for production deployment
  app.set('trust proxy', 1);

  // Security middleware
  app.use(helmet());
  app.use(cors({ origin: config.cors.origin, credentials: true }));

  // Body parsing
  app.use(express.json({ limit: '10kb' }));
  app.use(express.urlencoded({ limit: '10kb', extended: true }));

  // Request logging
  app.use(requestLogger);

  // Routes
  app.use('/health', createHealthRouter());

  // API v1 routes (placeholder)
  app.use('/v1/auth', (req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Auth module - not yet implemented',
      timestamp: new Date().toISOString(),
    });
  });

  app.use('/v1/users', (req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Users module - not yet implemented',
      timestamp: new Date().toISOString(),
    });
  });

  app.use('/v1/habits', (req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Habits module - not yet implemented',
      timestamp: new Date().toISOString(),
    });
  });

  // 404 handler
  app.use((req: Request, res: Response, next: NextFunction) => {
    throw new AppError('NOT_FOUND', 404, `Route ${req.path} not found`);
  });

  // Error handler (must be last)
  app.use(errorHandler);

  return app;
}
