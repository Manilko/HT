import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '@config/env';
import { JWTPayload } from '@types/index';
import { AppError } from './errorHandler';

declare global {
  namespace Express {
    interface Request {
      userId?: number;
      user?: JWTPayload;
    }
  }
}

export function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new AppError('UNAUTHORIZED', 401, 'Missing or invalid authorization header');
    }

    const token = authHeader.substring(7);
    const payload = jwt.verify(token, config.jwt.secret) as JWTPayload;

    req.userId = payload.sub;
    req.user = payload;

    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      throw new AppError('INVALID_TOKEN', 401, 'Invalid or expired token');
    }
    throw error;
  }
}

export function optionalAuthMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const payload = jwt.verify(token, config.jwt.secret) as JWTPayload;
      req.userId = payload.sub;
      req.user = payload;
    }
  } catch (error) {
    // Silently ignore auth errors for optional auth
  }

  next();
}
