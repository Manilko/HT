import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from '@config/env';
import { errorHandler, asyncHandler, AppError } from '@middleware/errorHandler';
import { logger } from '@utils/logger';
import { ApiResponse } from '@types/index';

export function createApp(): express.Application {
  const app = express();

  // Middleware
  app.use(helmet());
  app.use(cors({ origin: config.cors.origin }));
  app.use(express.json());

  // Request logging
  app.use((req, res, next) => {
    logger.debug(`${req.method} ${req.path}`);
    next();
  });

  // Health check
  app.get('/health', (req: Request, res: Response) => {
    const response: ApiResponse<{ status: string }> = {
      success: true,
      data: { status: 'ok' },
      timestamp: new Date().toISOString(),
    };
    res.json(response);
  });

  // API routes (placeholder)
  app.use('/v1/auth', (req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Auth module routes - not yet implemented',
      timestamp: new Date().toISOString(),
    });
  });

  app.use('/v1/users', (req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Users module routes - not yet implemented',
      timestamp: new Date().toISOString(),
    });
  });

  app.use('/v1/habits', (req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Habits module routes - not yet implemented',
      timestamp: new Date().toISOString(),
    });
  });

  // 404 handler
  app.use((req: Request, res: Response, next) => {
    throw new AppError('NOT_FOUND', 404, `Route ${req.path} not found`);
  });

  // Error handler (must be last)
  app.use(errorHandler);

  return app;
}
