//
//  005_create_migrations_table.ts
//  Create Migrations Tracking Table
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';

export async function up(): Promise<void> {
  await query(`
    CREATE TABLE IF NOT EXISTS migrations (
      id BIGSERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

export async function down(): Promise<void> {
  await query(`
    DROP TABLE IF EXISTS migrations CASCADE;
  `);
}
