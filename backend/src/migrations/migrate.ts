//
//  migrate.ts
//  Migration CLI
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { runMigrations, rollbackMigrations } from './runner';
import { logger } from '../config/logger';

const command = process.argv[2];

async function main() {
  try {
    if (command === 'up') {
      logger.info('Running migrations...');
      await runMigrations();
      logger.info('Migrations completed successfully');
      process.exit(0);
    } else if (command === 'down') {
      logger.info('Rolling back migrations...');
      await rollbackMigrations();
      logger.info('Rollback completed successfully');
      process.exit(0);
    } else {
      logger.error('Invalid command. Use: migrate.ts up|down');
      process.exit(1);
    }
  } catch (error) {
    logger.error('Migration error', error);
    process.exit(1);
  }
}

main();
