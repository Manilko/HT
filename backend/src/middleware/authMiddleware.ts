//
//  authMiddleware.ts
//  Authentication Middleware
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Request, Response, NextFunction } from 'express';
import { verifyToken, JWTPayload } from '../utils/tokenUtils';
import { AppError } from './errorHandler';
import { logger } from '../config/logger';

declare global {
  namespace Express {
    interface Request {
      user?: JWTPayload;
      userId?: number;
    }
  }
}

export function authenticateToken(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers['authorization'];
  const token = authHeader?.split(' ')[1]; // Bearer <token>

  if (!token) {
    throw new AppError('UNAUTHORIZED', 401, 'Missing authentication token');
  }

  try {
    const payload = verifyToken(token);
    req.user = payload;
    req.userId = payload.sub;
    next();
  } catch (error) {
    logger.warn('Token verification failed', { error: String(error) });
    throw new AppError('UNAUTHORIZED', 401, 'Invalid or expired token');
  }
}

export function optionalAuthenticate(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers['authorization'];
  const token = authHeader?.split(' ')[1];

  if (token) {
    try {
      const payload = verifyToken(token);
      req.user = payload;
      req.userId = payload.sub;
    } catch (error) {
      // Token was present but invalid - don't fail, just skip auth
      logger.debug('Optional token verification failed', { error: String(error) });
    }
  }

  next();
}
