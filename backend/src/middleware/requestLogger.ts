//
//  requestLogger.ts
//  Habit Tracker Backend
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Request, Response, NextFunction } from 'express';
import { logger } from '../config/logger';

export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  const method = req.method;
  const path = req.path;

  res.on('finish', () => {
    const duration = Date.now() - start;
    const statusCode = res.statusCode;

    logger.info(`${method} ${path}`, {
      statusCode,
      durationMs: duration,
    });
  });

  next();
}
