# Database Schema

PostgreSQL database for Habit Tracker.

## Tables

### users

User accounts from OAuth providers.

```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  oauth_id VARCHAR(255) UNIQUE NOT NULL,
  oauth_provider ENUM('google', 'github') NOT NULL,
  timezone VARCHAR(50) DEFAULT 'UTC',
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);
```

### habits

User habits (e.g., "Morning Run", "Read 20 pages").

```sql
CREATE TABLE habits (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  color VARCHAR(7),
  frequency VARCHAR(50) DEFAULT 'daily',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP,
  UNIQUE(user_id, name)
);
```

### check_ins

Daily check-in records for habits.

```sql
CREATE TABLE check_ins (
  id BIGSERIAL PRIMARY KEY,
  habit_id BIGINT NOT NULL REFERENCES habits(id),
  user_id BIGINT NOT NULL REFERENCES users(id),
  check_in_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(habit_id, check_in_date)
);
```

### streaks

Denormalized streak data for performance.

```sql
CREATE TABLE streaks (
  id BIGSERIAL PRIMARY KEY,
  habit_id BIGINT NOT NULL UNIQUE REFERENCES habits(id),
  current_streak_days INT DEFAULT 0,
  best_streak_days INT DEFAULT 0,
  best_streak_start_date DATE,
  best_streak_end_date DATE,
  total_check_ins INT DEFAULT 0,
  last_check_in_date DATE,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Indexes

```sql
CREATE INDEX idx_users_oauth_id ON users(oauth_id);
CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_habits_deleted ON habits(deleted_at);
CREATE INDEX idx_check_ins_habit_id ON check_ins(habit_id);
CREATE INDEX idx_check_ins_user_id ON check_ins(user_id);
CREATE INDEX idx_check_ins_date ON check_ins(check_in_date);
CREATE INDEX idx_streaks_habit_id ON streaks(habit_id);
```

## Key Decisions

- **Soft deletes**: `deleted_at` field preserves historical data
- **Denormalized streaks**: O(1) queries, updated transactionally
- **User timezone**: All date calculations use this field
- **Check-in date**: DATE type, no time component (date in user's timezone)
- **Unique constraints**: Prevent duplicates at database level

## Migration System

Migrations in `backend/migrations/` follow naming convention:
- `001_create_users_table.ts`
- `002_create_habits_table.ts`
- etc.

## Implementation Status

Schema is designed. Migration scripts coming soon.
