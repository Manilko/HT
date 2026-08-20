//
//  server.ts
//  Habit Tracker Backend - Entry Point
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import http from 'http';
import { createApp } from './config/app';
import { config, validateConfig } from './config/env';
import { testDatabaseConnection } from './config/database';
import { logger } from './config/logger';
import { WebSocketGateway } from './websocket';

async function startServer(): Promise<void> {
  try {
    logger.info('Starting Habit Tracker Backend');

    // Validate environment configuration
    validateConfig();
    logger.info('Configuration validated');

    // Test database connection
    await testDatabaseConnection();
    logger.info('Database connection established');

    // Create Express app
    const app = createApp();
    logger.info('Express app created');

    // Create HTTP server
    const httpServer = http.createServer(app);

    // Initialize WebSocket gateway
    const wsGateway = new WebSocketGateway(httpServer);
    logger.info('WebSocket gateway initialized');

    // Start server
    const port = config.server.port;
    const server = httpServer.listen(port, () => {
      logger.info(`Server listening on port ${port}`, {
        environment: config.server.nodeEnv,
        wsEnabled: true,
      });
    });

    // Graceful shutdown
    const gracefulShutdown = async (signal: string) => {
      logger.info(`${signal} received, shutting down gracefully`);

      server.close(async () => {
        await wsGateway.close();
        logger.info('Server shut down');
        process.exit(0);
      });

      // Force shutdown after 30 seconds
      setTimeout(() => {
        logger.error('Forced shutdown timeout');
        process.exit(1);
      }, 30000);
    };

    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Unhandled error handlers
    process.on('uncaughtException', (error: Error) => {
      logger.error('Uncaught exception', error);
      process.exit(1);
    });

    process.on('unhandledRejection', (reason: unknown) => {
      logger.error('Unhandled rejection', reason);
      process.exit(1);
    });
  } catch (error) {
    logger.error('Failed to start server', error);
    process.exit(1);
  }
}

startServer();
