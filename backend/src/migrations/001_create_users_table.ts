//
//  001_create_users_table.ts
//  Create Users Table
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';

export async function up(): Promise<void> {
  await query(`
    CREATE TABLE IF NOT EXISTS users (
      id BIGSERIAL PRIMARY KEY,
      provider VARCHAR(50) NOT NULL,
      provider_user_id VARCHAR(255) NOT NULL,
      email VARCHAR(255),
      display_name VARCHAR(255),
      avatar_url TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

      -- Composite unique constraint on provider + provider_user_id
      UNIQUE(provider, provider_user_id),

      -- Unique email (allows NULL for users without email)
      UNIQUE(email),

      -- Validate provider is known
      CHECK (provider IN ('google', 'github'))
    );

    -- Indexes for fast lookups
    CREATE INDEX IF NOT EXISTS idx_users_provider_id ON users(provider, provider_user_id);
    CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
    CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);
  `);
}

export async function down(): Promise<void> {
  await query(`
    DROP TABLE IF EXISTS users CASCADE;
  `);
}
