//
//  runner.ts
//  Migration Runner Utility
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';
import { logger } from '../config/logger';

// Import all migrations
import * as migration001 from './001_create_users_table';
import * as migration002 from './002_create_habits_table';
import * as migration003 from './003_create_check_ins_table';
import * as migration004 from './004_create_milestone_notifications_table';
import * as migration005 from './005_create_migrations_table';

interface MigrationModule {
  up(): Promise<void>;
  down(): Promise<void>;
}

const migrations: Map<string, MigrationModule> = new Map([
  ['001_create_users_table', migration001],
  ['002_create_habits_table', migration002],
  ['003_create_check_ins_table', migration003],
  ['004_create_milestone_notifications_table', migration004],
  ['005_create_migrations_table', migration005],
]);

export async function runMigrations(): Promise<void> {
  try {
    // Create migrations table if it doesn't exist
    await query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id BIGSERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    logger.info('Checking migrations');

    // Get executed migrations
    const executedMigrations = await query(`
      SELECT name FROM migrations ORDER BY executed_at;
    `);

    const executedNames = new Set(executedMigrations.rows.map((row: any) => row.name));

    // Run pending migrations
    for (const [name, migration] of migrations) {
      if (!executedNames.has(name)) {
        logger.info(`Running migration: ${name}`);
        try {
          await migration.up();
          await query(`INSERT INTO migrations (name) VALUES ($1)`, [name]);
          logger.info(`Completed migration: ${name}`);
        } catch (error) {
          logger.error(`Migration failed: ${name}`, error);
          throw error;
        }
      }
    }

    logger.info('All migrations completed');
  } catch (error) {
    logger.error('Migration runner error', error);
    throw error;
  }
}

export async function rollbackMigrations(): Promise<void> {
  try {
    logger.info('Rolling back all migrations');

    // Get all executed migrations in reverse order
    const executedMigrations = await query(`
      SELECT name FROM migrations ORDER BY executed_at DESC;
    `);

    // Rollback each migration
    for (const row of executedMigrations.rows) {
      const name = row.name;
      const migration = migrations.get(name);

      if (migration) {
        logger.info(`Rolling back migration: ${name}`);
        try {
          await migration.down();
          await query(`DELETE FROM migrations WHERE name = $1`, [name]);
          logger.info(`Rollback completed: ${name}`);
        } catch (error) {
          logger.error(`Rollback failed: ${name}`, error);
          throw error;
        }
      }
    }

    logger.info('All migrations rolled back');
  } catch (error) {
    logger.error('Rollback error', error);
    throw error;
  }
}
