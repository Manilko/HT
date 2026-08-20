-- ====================================
-- Habit Tracker Database Initialization
-- ====================================

-- Create enum types
CREATE TYPE oauth_provider AS ENUM ('google', 'github');

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  oauth_id VARCHAR(255) UNIQUE NOT NULL,
  oauth_provider oauth_provider NOT NULL,
  timezone VARCHAR(50) DEFAULT 'UTC',
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

-- Habits table
CREATE TABLE IF NOT EXISTS habits (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  color VARCHAR(7),
  frequency VARCHAR(50) DEFAULT 'daily',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP,
  UNIQUE(user_id, name)
);

-- Check-ins table
CREATE TABLE IF NOT EXISTS check_ins (
  id BIGSERIAL PRIMARY KEY,
  habit_id BIGINT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  check_in_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(habit_id, check_in_date)
);

-- Streaks table (denormalized for performance)
CREATE TABLE IF NOT EXISTS streaks (
  id BIGSERIAL PRIMARY KEY,
  habit_id BIGINT NOT NULL UNIQUE REFERENCES habits(id) ON DELETE CASCADE,
  current_streak_days INT DEFAULT 0,
  best_streak_days INT DEFAULT 0,
  best_streak_start_date DATE,
  best_streak_end_date DATE,
  total_check_ins INT DEFAULT 0,
  last_check_in_date DATE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_oauth_id ON users(oauth_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits(user_id);
CREATE INDEX IF NOT EXISTS idx_habits_deleted ON habits(deleted_at);
CREATE INDEX IF NOT EXISTS idx_check_ins_habit_id ON check_ins(habit_id);
CREATE INDEX IF NOT EXISTS idx_check_ins_user_id ON check_ins(user_id);
CREATE INDEX IF NOT EXISTS idx_check_ins_date ON check_ins(check_in_date);
CREATE INDEX IF NOT EXISTS idx_streaks_habit_id ON streaks(habit_id);

-- Grant privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO postgres;
