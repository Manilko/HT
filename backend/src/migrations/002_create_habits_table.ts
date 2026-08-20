//
//  002_create_habits_table.ts
//  Create Habits Table
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';

export async function up(): Promise<void> {
  await query(`
    -- Create habit status enum
    CREATE TYPE habit_status AS ENUM ('ACTIVE', 'PAUSED', 'ARCHIVED');

    CREATE TABLE IF NOT EXISTS habits (
      id BIGSERIAL PRIMARY KEY,
      user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name VARCHAR(255) NOT NULL,
      description TEXT,
      start_date DATE NOT NULL,
      status habit_status DEFAULT 'ACTIVE' NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

      -- Unique constraint: user can't have duplicate habit names
      UNIQUE(user_id, name),

      -- Validate start_date is not in future
      CHECK (start_date <= CURRENT_DATE)
    );

    -- Indexes for fast lookups
    CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);
    CREATE INDEX IF NOT EXISTS idx_habits_status ON habits(status);
    CREATE INDEX IF NOT EXISTS idx_habits_created_at ON habits(created_at);
  `);
}

export async function down(): Promise<void> {
  await query(`
    DROP TABLE IF EXISTS habits CASCADE;
    DROP TYPE IF EXISTS habit_status;
  `);
}
