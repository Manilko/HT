import { createApp } from './app';
import { config, validateConfig } from '@config/env';
import { logger } from '@utils/logger';

async function startServer(): Promise<void> {
  try {
    validateConfig();
    logger.info('Configuration validated');

    const app = createApp();
    logger.info('Express app created');

    const server = app.listen(config.server.port, () => {
      logger.info(`Server listening on port ${config.server.port}`, {
        environment: config.server.nodeEnv,
      });
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      logger.info('SIGTERM received, shutting down gracefully');
      server.close(() => {
        logger.info('Server shut down');
        process.exit(0);
      });
    });

    process.on('SIGINT', () => {
      logger.info('SIGINT received, shutting down gracefully');
      server.close(() => {
        logger.info('Server shut down');
        process.exit(0);
      });
    });
  } catch (error) {
    logger.error('Failed to start server', error as Error);
    process.exit(1);
  }
}

startServer();
