//
//  errorHandler.ts
//  Comprehensive Error Handling
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Request, Response, NextFunction } from 'express';
import { logger } from '../config/logger';

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
  timestamp: string;
}

export class AppError extends Error {
  constructor(
    public code: string,
    public statusCode: number,
    message: string,
    public details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = 'AppError';
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

export function errorHandler(
  err: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const timestamp = new Date().toISOString();

  // Handle AppError instances
  if (err instanceof AppError) {
    logger.warn(`API Error: ${err.code}`, {
      statusCode: err.statusCode,
      path: req.path,
      method: req.method,
      userId: (req as any).userId,
    });

    const response: ApiResponse = {
      success: false,
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
      timestamp,
    };

    res.status(err.statusCode).json(response);
    return;
  }

  // Handle database errors (never expose to client)
  if (err.message && err.message.includes('duplicate key')) {
    logger.warn('Database constraint violation', {
      path: req.path,
      userId: (req as any).userId,
    });

    const response: ApiResponse = {
      success: false,
      error: {
        code: 'DUPLICATE_CHECK_IN',
        message: 'You have already completed this habit today.',
      },
      timestamp,
    };

    res.status(409).json(response);
    return;
  }

  // Handle other database errors
  if (err.message && (err.message.includes('database') || err.message.includes('query'))) {
    logger.error('Database error', {
      message: err.message,
      stack: err.stack,
      path: req.path,
      userId: (req as any).userId,
    });

    const response: ApiResponse = {
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'A database error occurred. Please try again later.',
      },
      timestamp,
    };

    res.status(500).json(response);
    return;
  }

  // Handle validation errors
  if (err.message && err.message.toLowerCase().includes('invalid')) {
    logger.warn('Validation error', {
      message: err.message,
      path: req.path,
    });

    const response: ApiResponse = {
      success: false,
      error: {
        code: 'INVALID_REQUEST',
        message: 'Your request contains invalid data. Please try again.',
      },
      timestamp,
    };

    res.status(400).json(response);
    return;
  }

  // Default unhandled error
  logger.error('Unhandled error', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    userId: (req as any).userId,
  });

  const response: ApiResponse = {
    success: false,
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Something went wrong. Please try again later.',
    },
    timestamp,
  };

  res.status(500).json(response);
}

export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<void>,
) {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}
