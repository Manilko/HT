//
//  checkIns.ts
//  Check-ins Routes
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Router, Request, Response } from 'express';
import { authenticateToken } from '../middleware/authMiddleware';
import { AppError, asyncHandler, ApiResponse } from '../middleware/errorHandler';
import {
  createCheckIn,
  getCheckInsByHabitId,
  getTodaysCheckIn,
  deleteTodaysCheckIn,
  CheckIn,
} from '../repositories/checkInRepository';
import { getHabitById } from '../repositories/habitRepository';
import { logger } from '../config/logger';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

function checkInToResponse(checkIn: CheckIn) {
  return {
    id: checkIn.id,
    habitId: checkIn.habit_id,
    userId: checkIn.user_id,
    checkInDate: checkIn.check_in_date,
    createdAt: checkIn.created_at,
  };
}

// MARK: - POST /habits/:habitId/check-ins - Create today's check-in

router.post(
  '/:habitId/check-ins',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const habitId = parseInt(req.params.habitId, 10);

    if (isNaN(habitId)) {
      throw new AppError('INVALID_REQUEST', 400, 'Invalid habit ID');
    }

    logger.info(`Creating check-in for habit ${habitId} by user ${userId}`);

    // Verify user owns the habit
    const habit = await getHabitById(habitId);
    if (!habit || habit.user_id !== userId) {
      throw new AppError('FORBIDDEN', 403, 'You do not have access to this habit');
    }

    // Check habit status
    if (habit.status !== 'ACTIVE') {
      throw new AppError(
        'INVALID_REQUEST',
        400,
        `Cannot check in for ${habit.status.toLowerCase()} habit`,
      );
    }

    // Create check-in for today
    const today = new Date().toISOString().split('T')[0];

    try {
      const checkIn = await createCheckIn(habitId, userId, today);

      const response: ApiResponse = {
        success: true,
        data: checkInToResponse(checkIn),
        timestamp: new Date().toISOString(),
      };

      res.status(201).json(response);
    } catch (error: unknown) {
      const errorMsg = error instanceof Error ? error.message : 'Failed to create check-in';

      if (errorMsg.includes('duplicate key')) {
        // Already checked in today
        throw new AppError('INVALID_REQUEST', 409, 'Already checked in today');
      }

      throw new AppError('INVALID_REQUEST', 400, errorMsg);
    }
  }),
);

// MARK: - GET /habits/:habitId/check-ins - Get all check-ins for habit

router.get(
  '/:habitId/check-ins',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const habitId = parseInt(req.params.habitId, 10);

    if (isNaN(habitId)) {
      throw new AppError('INVALID_REQUEST', 400, 'Invalid habit ID');
    }

    logger.info(`Fetching check-ins for habit ${habitId}`);

    const checkIns = await getCheckInsByHabitId(habitId, userId);

    const response: ApiResponse = {
      success: true,
      data: {
        checkIns: checkIns.map(checkInToResponse),
        count: checkIns.length,
      },
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

// MARK: - DELETE /habits/:habitId/check-ins/today - Undo today's check-in

router.delete(
  '/:habitId/check-ins/today',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const habitId = parseInt(req.params.habitId, 10);

    if (isNaN(habitId)) {
      throw new AppError('INVALID_REQUEST', 400, 'Invalid habit ID');
    }

    logger.info(`Deleting today's check-in for habit ${habitId} by user ${userId}`);

    try {
      await deleteTodaysCheckIn(habitId, userId);

      const response: ApiResponse = {
        success: true,
        data: { habitId },
        timestamp: new Date().toISOString(),
      };

      res.status(200).json(response);
    } catch (error: unknown) {
      const errorMsg = error instanceof Error ? error.message : 'Failed to delete check-in';

      if (errorMsg.includes('not found')) {
        throw new AppError('NOT_FOUND', 404, 'No check-in found for today');
      }

      if (errorMsg.includes('access denied')) {
        throw new AppError('FORBIDDEN', 403, 'You do not have access to this habit');
      }

      throw new AppError('INVALID_REQUEST', 400, errorMsg);
    }
  }),
);

export function createCheckInsRouter() {
  return router;
}
