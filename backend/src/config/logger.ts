//
//  logger.ts
//  Habit Tracker Backend
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const logLevels: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const currentLogLevel = logLevels[(process.env.LOG_LEVEL as LogLevel) || 'info'];

function formatTimestamp(): string {
  return new Date().toISOString();
}

function formatLog(level: LogLevel, message: string, data?: unknown): string {
  const timestamp = formatTimestamp();
  const dataStr = data ? ` ${JSON.stringify(data)}` : '';
  return `[${timestamp}] [${level.toUpperCase()}] ${message}${dataStr}`;
}

export const logger = {
  debug: (message: string, data?: unknown): void => {
    if (currentLogLevel <= logLevels.debug) {
      console.log(formatLog('debug', message, data));
    }
  },

  info: (message: string, data?: unknown): void => {
    if (currentLogLevel <= logLevels.info) {
      console.log(formatLog('info', message, data));
    }
  },

  warn: (message: string, data?: unknown): void => {
    if (currentLogLevel <= logLevels.warn) {
      console.warn(formatLog('warn', message, data));
    }
  },

  error: (message: string, error?: Error | unknown): void => {
    if (currentLogLevel <= logLevels.error) {
      if (error instanceof Error) {
        console.error(formatLog('error', message, { message: error.message, stack: error.stack }));
      } else {
        console.error(formatLog('error', message, error));
      }
    }
  },
};
