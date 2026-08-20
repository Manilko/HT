//
//  userRepository.ts
//  User Repository
//
//  Created by Manilko, Yevhenii on 2026-08-20.
//

import { query } from '../config/database';
import { logger } from '../config/logger';

export interface User {
  id: number;
  provider: string;
  provider_user_id: string;
  email: string | null;
  display_name: string;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface CreateUserData {
  provider: string;
  provider_user_id: string;
  email: string | null;
  display_name: string;
  avatar_url: string | null;
}

export async function findOrCreateUser(data: CreateUserData): Promise<User> {
  try {
    // Try to find existing user by provider + provider_user_id
    const existingUser = await query(
      `SELECT * FROM users WHERE provider = $1 AND provider_user_id = $2`,
      [data.provider, data.provider_user_id],
    );

    if (existingUser.rows.length > 0) {
      logger.info(`Found existing user: ${data.provider}/${data.provider_user_id}`);
      return existingUser.rows[0] as User;
    }

    // Create new user
    logger.info(`Creating new user: ${data.provider}/${data.provider_user_id}`);
    const result = await query(
      `INSERT INTO users (provider, provider_user_id, email, display_name, avatar_url, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING *`,
      [data.provider, data.provider_user_id, data.email, data.display_name, data.avatar_url],
    );

    return result.rows[0] as User;
  } catch (error) {
    logger.error(`Failed to find or create user`, error);
    throw error;
  }
}

export async function getUserById(userId: number): Promise<User | null> {
  try {
    const result = await query(`SELECT * FROM users WHERE id = $1`, [userId]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0] as User;
  } catch (error) {
    logger.error(`Failed to get user by ID: ${userId}`, error);
    throw error;
  }
}

export async function getUserByEmail(email: string): Promise<User | null> {
  try {
    const result = await query(`SELECT * FROM users WHERE email = $1`, [email]);

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0] as User;
  } catch (error) {
    logger.error(`Failed to get user by email`, error);
    throw error;
  }
}
