//
//  habits.ts
//  Habits Routes
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { Router, Request, Response } from 'express';
import { authenticateToken } from '../middleware/authMiddleware';
import { AppError, asyncHandler, ApiResponse } from '../middleware/errorHandler';
import {
  createHabit,
  getHabitsByUserId,
  getHabitById,
  updateHabit,
  deleteHabit,
  canUserAccessHabit,
  isHabitArchived,
  Habit,
  HabitStatus,
  CreateHabitData,
  UpdateHabitData,
  HabitFilterOptions,
} from '../repositories/habitRepository';
import { logger } from '../config/logger';

const router = Router();

// Apply authentication middleware to all routes
router.use(authenticateToken);

// MARK: - Helpers

function validateHabitName(name: string): void {
  if (!name || typeof name !== 'string') {
    throw new AppError('INVALID_REQUEST', 400, 'Habit name is required');
  }

  if (name.trim().length === 0) {
    throw new AppError('INVALID_REQUEST', 400, 'Habit name cannot be empty');
  }

  if (name.length > 255) {
    throw new AppError('INVALID_REQUEST', 400, 'Habit name cannot exceed 255 characters');
  }
}

function validateDescription(description: string | null | undefined): void {
  if (description !== null && description !== undefined && typeof description !== 'string') {
    throw new AppError('INVALID_REQUEST', 400, 'Description must be a string');
  }

  if (description && description.length > 1000) {
    throw new AppError('INVALID_REQUEST', 400, 'Description cannot exceed 1000 characters');
  }
}

function validateStartDate(startDate: string): void {
  if (!startDate || typeof startDate !== 'string') {
    throw new AppError('INVALID_REQUEST', 400, 'Start date is required');
  }

  const date = new Date(startDate);
  if (isNaN(date.getTime())) {
    throw new AppError('INVALID_REQUEST', 400, 'Invalid start date format');
  }

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const parsedDate = new Date(startDate);
  parsedDate.setHours(0, 0, 0, 0);

  if (parsedDate > today) {
    throw new AppError('INVALID_REQUEST', 400, 'Start date cannot be in the future');
  }
}

function validateStatus(status: string): asserts status is HabitStatus {
  const validStatuses: HabitStatus[] = ['ACTIVE', 'PAUSED', 'ARCHIVED'];

  if (!validStatuses.includes(status as HabitStatus)) {
    throw new AppError(
      'INVALID_REQUEST',
      400,
      `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
    );
  }
}

function validateStatusTransition(currentStatus: HabitStatus, newStatus: HabitStatus): void {
  if (currentStatus === newStatus) {
    return; // No transition
  }

  // Valid transitions
  const validTransitions: Record<HabitStatus, HabitStatus[]> = {
    ACTIVE: ['PAUSED', 'ARCHIVED'],
    PAUSED: ['ACTIVE', 'ARCHIVED'],
    ARCHIVED: [], // Archived habits cannot change status
  };

  if (!validTransitions[currentStatus].includes(newStatus)) {
    throw new AppError(
      'INVALID_REQUEST',
      400,
      `Cannot transition from ${currentStatus} to ${newStatus}`,
    );
  }
}

function habitToResponse(habit: Habit) {
  return {
    id: habit.id,
    name: habit.name,
    description: habit.description,
    startDate: habit.start_date,
    status: habit.status,
    createdAt: habit.created_at,
    updatedAt: habit.updated_at,
  };
}

// MARK: - GET /habits - List user's habits with optional filters

router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const search = typeof req.query.search === 'string' ? req.query.search : undefined;
    const statusParam = req.query.status;

    logger.info(`Fetching habits for user ${userId}${search ? ` with search: ${search}` : ''}${statusParam ? ` with statuses: ${statusParam}` : ''}`);

    // Parse status filter
    let statuses: HabitStatus[] | undefined;
    if (statusParam) {
      const statusList = Array.isArray(statusParam) ? statusParam : [statusParam];
      statuses = (statusList as string[]).filter(s => ['ACTIVE', 'PAUSED', 'ARCHIVED'].includes(s)) as HabitStatus[];

      if (statuses.length === 0) {
        throw new AppError('INVALID_REQUEST', 400, 'Invalid status filter values');
      }
    }

    const filters: HabitFilterOptions = {
      search: search && search.length > 0 ? search : undefined,
      statuses,
    };

    const habits = await getHabitsByUserId(userId, filters);

    const response: ApiResponse = {
      success: true,
      data: {
        habits: habits.map(habitToResponse),
        count: habits.length,
      },
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

// MARK: - GET /habits/:id - Get single habit

router.get(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const habitId = parseInt(req.params.id, 10);

    if (isNaN(habitId)) {
      throw new AppError('INVALID_REQUEST', 400, 'Invalid habit ID');
    }

    logger.info(`Fetching habit ${habitId} for user ${userId}`);

    // Verify user owns this habit
    const hasAccess = await canUserAccessHabit(userId, habitId);
    if (!hasAccess) {
      throw new AppError('FORBIDDEN', 403, 'You do not have access to this habit');
    }

    const habit = await getHabitById(habitId);
    if (!habit) {
      throw new AppError('NOT_FOUND', 404, 'Habit not found');
    }

    const response: ApiResponse = {
      success: true,
      data: habitToResponse(habit),
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

// MARK: - POST /habits - Create habit

router.post(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const { name, description, startDate } = req.body;

    // Validation
    validateHabitName(name);
    validateDescription(description);
    validateStartDate(startDate);

    logger.info(`Creating habit for user ${userId}: ${name}`);

    const createData: CreateHabitData = {
      name: name.trim(),
      description: description ? description.trim() : null,
      start_date: startDate,
    };

    const habit = await createHabit(userId, createData);

    const response: ApiResponse = {
      success: true,
      data: habitToResponse(habit),
      timestamp: new Date().toISOString(),
    };

    res.status(201).json(response);
  }),
);

// MARK: - PATCH /habits/:id - Update habit

router.patch(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const habitId = parseInt(req.params.id, 10);
    const { name, description, status } = req.body;

    if (isNaN(habitId)) {
      throw new AppError('INVALID_REQUEST', 400, 'Invalid habit ID');
    }

    logger.info(`Updating habit ${habitId} for user ${userId}`);

    // Verify user owns this habit
    const hasAccess = await canUserAccessHabit(userId, habitId);
    if (!hasAccess) {
      throw new AppError('FORBIDDEN', 403, 'You do not have access to this habit');
    }

    // Get current habit
    const currentHabit = await getHabitById(habitId);
    if (!currentHabit) {
      throw new AppError('NOT_FOUND', 404, 'Habit not found');
    }

    // Archived habits are read-only
    if (currentHabit.status === 'ARCHIVED' && status !== 'ARCHIVED') {
      throw new AppError(
        'INVALID_REQUEST',
        400,
        'Archived habits cannot be modified (except status)',
      );
    }

    // Prepare update data
    const updateData: UpdateHabitData = {};

    if (name !== undefined) {
      validateHabitName(name);
      updateData.name = name.trim();
    }

    if (description !== undefined) {
      validateDescription(description);
      updateData.description = description ? description.trim() : null;
    }

    if (status !== undefined) {
      validateStatus(status);
      // Validate status transition
      validateStatusTransition(currentHabit.status, status);
      updateData.status = status;
    }

    // Prevent modification of archived habits
    if (currentHabit.status === 'ARCHIVED' && (name || description)) {
      throw new AppError('INVALID_REQUEST', 400, 'Cannot modify archived habits');
    }

    const updatedHabit = await updateHabit(habitId, updateData);

    const response: ApiResponse = {
      success: true,
      data: habitToResponse(updatedHabit),
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

// MARK: - DELETE /habits/:id - Delete habit (requires archived status)

router.delete(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.userId!;
    const habitId = parseInt(req.params.id, 10);

    if (isNaN(habitId)) {
      throw new AppError('INVALID_REQUEST', 400, 'Invalid habit ID');
    }

    logger.info(`Deleting habit ${habitId} for user ${userId}`);

    // Verify user owns this habit
    const hasAccess = await canUserAccessHabit(userId, habitId);
    if (!hasAccess) {
      throw new AppError('FORBIDDEN', 403, 'You do not have access to this habit');
    }

    // Check habit exists and is archived
    const habit = await getHabitById(habitId);
    if (!habit) {
      throw new AppError('NOT_FOUND', 404, 'Habit not found');
    }

    if (habit.status !== 'ARCHIVED') {
      throw new AppError(
        'INVALID_REQUEST',
        400,
        'Only archived habits can be deleted. Archive the habit first.',
      );
    }

    // Delete habit (will cascade delete check-ins and notifications)
    await deleteHabit(habitId);

    const response: ApiResponse = {
      success: true,
      data: { id: habitId },
      timestamp: new Date().toISOString(),
    };

    res.status(200).json(response);
  }),
);

export function createHabitsRouter() {
  return router;
}
