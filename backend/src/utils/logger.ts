import { config } from '@config/env';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const logLevels: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const currentLogLevel = logLevels[config.server.logLevel as LogLevel] || logLevels.info;

export const logger = {
  debug: (message: string, meta?: Record<string, unknown>): void => {
    if (currentLogLevel <= logLevels.debug) {
      console.log(`[DEBUG] ${message}`, meta);
    }
  },

  info: (message: string, meta?: Record<string, unknown>): void => {
    if (currentLogLevel <= logLevels.info) {
      console.log(`[INFO] ${message}`, meta);
    }
  },

  warn: (message: string, meta?: Record<string, unknown>): void => {
    if (currentLogLevel <= logLevels.warn) {
      console.warn(`[WARN] ${message}`, meta);
    }
  },

  error: (message: string, error?: Error | Record<string, unknown>): void => {
    if (currentLogLevel <= logLevels.error) {
      if (error instanceof Error) {
        console.error(`[ERROR] ${message}`, error.message, error.stack);
      } else {
        console.error(`[ERROR] ${message}`, error);
      }
    }
  },
};
