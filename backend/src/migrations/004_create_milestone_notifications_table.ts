//
//  004_create_milestone_notifications_table.ts
//  Create Milestone Notifications Table
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';

export async function up(): Promise<void> {
  await query(`
    CREATE TABLE IF NOT EXISTS milestone_notifications (
      id BIGSERIAL PRIMARY KEY,
      habit_id BIGINT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
      user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      milestone INT NOT NULL,
      delivered BOOLEAN DEFAULT FALSE,
      read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      delivered_at TIMESTAMP,
      read_at TIMESTAMP,

      -- Validate milestone is one of the supported values
      CHECK (milestone IN (3, 7, 30)),

      -- Unique: one notification per habit per milestone
      UNIQUE(habit_id, milestone)
    );

    -- Indexes for fast lookups
    CREATE INDEX IF NOT EXISTS idx_milestone_notifications_habit_id ON milestone_notifications(habit_id);
    CREATE INDEX IF NOT EXISTS idx_milestone_notifications_user_id ON milestone_notifications(user_id);
    CREATE INDEX IF NOT EXISTS idx_milestone_notifications_delivered ON milestone_notifications(delivered);
    CREATE INDEX IF NOT EXISTS idx_milestone_notifications_read ON milestone_notifications(read);
    CREATE INDEX IF NOT EXISTS idx_milestone_notifications_created_at ON milestone_notifications(created_at);
  `);
}

export async function down(): Promise<void> {
  await query(`
    DROP TABLE IF EXISTS milestone_notifications CASCADE;
  `);
}
