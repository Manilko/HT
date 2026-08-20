//
//  003_create_check_ins_table.ts
//  Create Check-ins Table
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';

export async function up(): Promise<void> {
  await query(`
    CREATE TABLE IF NOT EXISTS check_ins (
      id BIGSERIAL PRIMARY KEY,
      habit_id BIGINT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
      user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      check_in_date DATE NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

      -- Unique constraint: one check-in per habit per date
      UNIQUE(habit_id, check_in_date),

      -- Validate check_in_date is not in future
      CHECK (check_in_date <= CURRENT_DATE)
    );

    -- Indexes for fast lookups
    CREATE INDEX IF NOT EXISTS idx_check_ins_habit_id ON check_ins(habit_id);
    CREATE INDEX IF NOT EXISTS idx_check_ins_user_id ON check_ins(user_id);
    CREATE INDEX IF NOT EXISTS idx_check_ins_date ON check_ins(check_in_date);
    CREATE INDEX IF NOT EXISTS idx_check_ins_habit_date ON check_ins(habit_id, check_in_date);
  `);
}

export async function down(): Promise<void> {
  await query(`
    DROP TABLE IF EXISTS check_ins CASCADE;
  `);
}
