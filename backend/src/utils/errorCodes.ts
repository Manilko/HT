//
//  errorCodes.ts
//  Standardized Error Codes and Messages
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

export interface ErrorDetail {
  code: string;
  statusCode: number;
  userMessage: string;
  logMessage?: string;
}

export const ERROR_CODES = {
  // Authentication Errors (401)
  MISSING_TOKEN: {
    code: 'MISSING_TOKEN',
    statusCode: 401,
    userMessage: 'Authentication token is required',
    logMessage: 'Request missing Authorization header',
  },
  INVALID_TOKEN: {
    code: 'INVALID_TOKEN',
    statusCode: 401,
    userMessage: 'Your session has expired. Please sign in again.',
    logMessage: 'Token verification failed',
  },
  EXPIRED_TOKEN: {
    code: 'EXPIRED_TOKEN',
    statusCode: 401,
    userMessage: 'Your session has expired. Please sign in again.',
    logMessage: 'Token has expired',
  },
  MALFORMED_TOKEN: {
    code: 'MALFORMED_TOKEN',
    statusCode: 401,
    userMessage: 'Your session is invalid. Please sign in again.',
    logMessage: 'Token format is invalid',
  },

  // Authorization Errors (403)
  FORBIDDEN: {
    code: 'FORBIDDEN',
    statusCode: 403,
    userMessage: 'You do not have permission to access this resource.',
    logMessage: 'User lacks required permissions',
  },
  HABIT_NOT_OWNED: {
    code: 'FORBIDDEN',
    statusCode: 403,
    userMessage: 'You do not have access to this habit.',
    logMessage: 'User attempting to access habit they do not own',
  },
  CHECK_IN_NOT_OWNED: {
    code: 'FORBIDDEN',
    statusCode: 403,
    userMessage: 'You do not have access to this check-in.',
    logMessage: 'User attempting to access check-in they do not own',
  },

  // Validation Errors (400)
  INVALID_REQUEST: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Your request contains invalid data. Please try again.',
    logMessage: 'Request validation failed',
  },
  INVALID_HABIT_NAME: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Habit name is required and cannot be empty.',
    logMessage: 'Invalid habit name provided',
  },
  INVALID_START_DATE: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Start date cannot be in the future.',
    logMessage: 'Invalid start date provided',
  },
  INVALID_STATUS: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Invalid habit status.',
    logMessage: 'Invalid status value provided',
  },
  INVALID_STATUS_TRANSITION: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'This habit status change is not allowed.',
    logMessage: 'Invalid status transition',
  },
  ARCHIVED_HABIT_READ_ONLY: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Archived habits cannot be modified.',
    logMessage: 'Attempted to modify archived habit',
  },
  PAUSED_HABIT_NO_CHECKIN: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Cannot check in for paused habits.',
    logMessage: 'Attempted check-in for paused habit',
  },
  ARCHIVED_HABIT_NO_CHECKIN: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Cannot check in for archived habits.',
    logMessage: 'Attempted check-in for archived habit',
  },

  // Duplicate Check-in (409)
  DUPLICATE_CHECK_IN: {
    code: 'DUPLICATE_CHECK_IN',
    statusCode: 409,
    userMessage: 'You have already completed this habit today.',
    logMessage: 'Duplicate check-in attempt for today',
  },

  // Not Found (404)
  NOT_FOUND: {
    code: 'NOT_FOUND',
    statusCode: 404,
    userMessage: 'The requested resource was not found.',
    logMessage: 'Resource not found',
  },
  HABIT_NOT_FOUND: {
    code: 'NOT_FOUND',
    statusCode: 404,
    userMessage: 'Habit not found.',
    logMessage: 'Habit with ID not found',
  },
  CHECK_IN_NOT_FOUND: {
    code: 'NOT_FOUND',
    statusCode: 404,
    userMessage: 'No check-in found for today.',
    logMessage: 'Check-in not found',
  },
  USER_NOT_FOUND: {
    code: 'NOT_FOUND',
    statusCode: 404,
    userMessage: 'User not found.',
    logMessage: 'User with ID not found',
  },

  // OAuth Errors (400)
  INVALID_AUTH_CODE: {
    code: 'INVALID_AUTH_CODE',
    statusCode: 400,
    userMessage: 'Authentication code is invalid or expired. Please try signing in again.',
    logMessage: 'Invalid authorization code provided',
  },
  OAUTH_EXCHANGE_FAILED: {
    code: 'OAUTH_EXCHANGE_FAILED',
    statusCode: 400,
    userMessage: 'Failed to authenticate with the provider. Please try again.',
    logMessage: 'OAuth token exchange failed',
  },
  OAUTH_USER_INFO_FAILED: {
    code: 'OAUTH_USER_INFO_FAILED',
    statusCode: 400,
    userMessage: 'Failed to retrieve user information. Please try again.',
    logMessage: 'Failed to fetch user info from OAuth provider',
  },

  // Server Errors (500)
  INTERNAL_ERROR: {
    code: 'INTERNAL_ERROR',
    statusCode: 500,
    userMessage: 'Something went wrong. Please try again later.',
    logMessage: 'Internal server error',
  },
  DATABASE_ERROR: {
    code: 'INTERNAL_ERROR',
    statusCode: 500,
    userMessage: 'A database error occurred. Please try again later.',
    logMessage: 'Database operation failed',
  },
  TRANSACTION_FAILED: {
    code: 'INTERNAL_ERROR',
    statusCode: 500,
    userMessage: 'The operation could not be completed. Please try again.',
    logMessage: 'Database transaction failed',
  },
  WEBSOCKET_ERROR: {
    code: 'INTERNAL_ERROR',
    statusCode: 500,
    userMessage: 'Connection error. Please refresh.',
    logMessage: 'WebSocket operation failed',
  },

  // WebSocket Specific
  WEBSOCKET_AUTH_REQUIRED: {
    code: 'UNAUTHORIZED',
    statusCode: 401,
    userMessage: 'Connection authentication required',
    logMessage: 'WebSocket connection attempted without token',
  },
  WEBSOCKET_INVALID_AUTH: {
    code: 'UNAUTHORIZED',
    statusCode: 401,
    userMessage: 'Connection authentication failed',
    logMessage: 'WebSocket connection with invalid token',
  },
  WEBSOCKET_INVALID_MESSAGE: {
    code: 'INVALID_REQUEST',
    statusCode: 400,
    userMessage: 'Invalid message format',
    logMessage: 'WebSocket received invalid message format',
  },
};

export type ErrorCode = keyof typeof ERROR_CODES;

export function getErrorDetail(errorCode: ErrorCode): ErrorDetail {
  return ERROR_CODES[errorCode];
}

export function formatErrorResponse(
  errorCode: ErrorCode,
  additionalContext?: string,
): {
  code: string;
  message: string;
  details?: Record<string, unknown>;
} {
  const detail = getErrorDetail(errorCode);
  return {
    code: detail.code,
    message: detail.userMessage,
    ...(additionalContext && { details: { context: additionalContext } }),
  };
}
