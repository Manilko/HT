# Database Schema Documentation

## Overview

The Habit Tracker database is built on PostgreSQL and follows a normalized, relational design that enforces data integrity through constraints and relationships. The schema supports multi-provider OAuth authentication, per-user habit tracking, daily check-ins, and milestone-based notifications.

## Architecture Principles

- **User Identification**: Users are identified by `(provider, provider_user_id)` tuple, allowing a single user to authenticate through multiple OAuth providers
- **No Password Storage**: SSO-only authentication; no password fields are stored in the database
- **Cascading Deletes**: Deleting a user automatically removes all associated habits, check-ins, and notifications
- **Data Validation**: Constraints enforce date validity, enum values, and business rules at the database level
- **Performance**: Strategic indexes on frequently queried columns enable efficient queries

## Tables

### users

Stores user account information.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-----------|---|
| id | BIGSERIAL | PRIMARY KEY | Unique user identifier |
| provider | VARCHAR(50) | NOT NULL, CHECK (provider IN ('google', 'github')) | OAuth provider (google or github) |
| provider_user_id | VARCHAR(255) | NOT NULL | User ID from the OAuth provider |
| email | VARCHAR(255) | UNIQUE, nullable | User email address (optional, unique when present) |
| display_name | VARCHAR(255) | | User's display name from OAuth profile |
| avatar_url | TEXT | nullable | URL to user's profile avatar |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Account creation timestamp |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Last account update timestamp |

**Constraints:**

- **Composite Unique**: `UNIQUE(provider, provider_user_id)` — ensures each OAuth provider identity is used by only one user
- **Provider Enum**: `CHECK (provider IN ('google', 'github'))` — restricts to supported OAuth providers
- **Email Uniqueness**: `UNIQUE(email)` — when email is provided, it must be unique across all users

**Indexes:**

- `idx_users_provider_user_id` — composite index on `(provider, provider_user_id)` for fast user lookups by OAuth identity
- `idx_users_email` — index on `email` for email-based lookups
- `idx_users_created_at` — index on `created_at` for sorting and pagination

**Design Notes:**

- Email is nullable because OAuth providers may not always provide an email address
- The `(provider, provider_user_id)` tuple uniquely identifies a user account, not individual users across providers
- If a user wants to link multiple OAuth providers, a separate user_connections table would be added in future iterations

---

### habits

Stores habits created by users.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-----------|---|
| id | BIGSERIAL | PRIMARY KEY | Unique habit identifier |
| user_id | BIGINT | NOT NULL, FK → users(id) ON DELETE CASCADE | Owner of the habit |
| name | VARCHAR(255) | NOT NULL | Habit name (e.g., "Morning Run") |
| description | TEXT | nullable | Optional description of the habit |
| start_date | DATE | NOT NULL, CHECK (start_date <= CURRENT_DATE) | Date the habit was created |
| status | habit_status ENUM | DEFAULT 'ACTIVE' | Current status: ACTIVE, PAUSED, or ARCHIVED |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Habit creation timestamp |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Last habit update timestamp |

**Constraints:**

- **Foreign Key**: `user_id` references `users(id)` with CASCADE delete
- **Per-User Uniqueness**: `UNIQUE(user_id, name)` — users cannot have duplicate habit names
- **Start Date Validation**: `CHECK (start_date <= CURRENT_DATE)` — start date cannot be in the future

**Enum: habit_status**

```
ACTIVE    — Habit is currently active and user is tracking check-ins
PAUSED    — Habit is temporarily paused; user may resume later
ARCHIVED  — Habit is archived; no longer active but data is preserved
```

**Indexes:**

- `idx_habits_user_id` — fast lookup of all habits for a user
- `idx_habits_status` — filter habits by status (e.g., show only ACTIVE habits)
- `idx_habits_created_at` — support date-based sorting and pagination

**Design Notes:**

- Each user's habit names must be unique to prevent confusion in the UI
- The enum type `habit_status` is defined at the database level to enforce valid statuses
- Soft delete via PAUSED/ARCHIVED instead of hard delete preserves habit history and statistics

---

### check_ins

Stores daily check-ins for habits.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-----------|---|
| id | BIGSERIAL | PRIMARY KEY | Unique check-in identifier |
| habit_id | BIGINT | NOT NULL, FK → habits(id) ON DELETE CASCADE | Associated habit |
| user_id | BIGINT | NOT NULL, FK → users(id) ON DELETE CASCADE | User who created the check-in |
| check_in_date | DATE | NOT NULL, CHECK (check_in_date <= CURRENT_DATE) | Date of the check-in |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Check-in creation timestamp |

**Constraints:**

- **Foreign Key (Habit)**: `habit_id` references `habits(id)` with CASCADE delete
- **Foreign Key (User)**: `user_id` references `users(id)` with CASCADE delete (denormalized for query efficiency)
- **Daily Uniqueness**: `UNIQUE(habit_id, check_in_date)` — one check-in per habit per day
- **Date Validation**: `CHECK (check_in_date <= CURRENT_DATE)` — cannot check in for future dates

**Indexes:**

- `idx_check_ins_habit_id` — retrieve all check-ins for a habit
- `idx_check_ins_user_id` — retrieve all check-ins for a user
- `idx_check_ins_date` — filter by check-in date (for date range queries)
- `idx_check_ins_habit_date` — composite index for efficient `(habit_id, check_in_date)` lookups

**Design Notes:**

- `user_id` is stored redundantly (denormalized) to enable efficient queries across all user check-ins without joining to habits
- The composite unique constraint prevents duplicate check-ins on the same day
- Date validation is enforced at the database level to catch application bugs early

---

### milestone_notifications

Stores milestone notifications for habit streaks.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-----------|---|
| id | BIGSERIAL | PRIMARY KEY | Unique notification identifier |
| habit_id | BIGINT | NOT NULL, FK → habits(id) ON DELETE CASCADE | Associated habit |
| user_id | BIGINT | NOT NULL, FK → users(id) ON DELETE CASCADE | User who owns the habit |
| milestone | INT | NOT NULL, CHECK (milestone IN (3, 7, 30)) | Milestone days (3, 7, or 30) |
| delivered | BOOLEAN | DEFAULT FALSE | Whether notification was delivered to user |
| read | BOOLEAN | DEFAULT FALSE | Whether user has read the notification |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Notification creation timestamp |
| delivered_at | TIMESTAMP | nullable | Timestamp when notification was delivered |
| read_at | TIMESTAMP | nullable | Timestamp when user read the notification |

**Constraints:**

- **Foreign Key (Habit)**: `habit_id` references `habits(id)` with CASCADE delete
- **Foreign Key (User)**: `user_id` references `users(id)` with CASCADE delete
- **Milestone Validation**: `CHECK (milestone IN (3, 7, 30))` — restricts to supported milestones
- **Per-Habit Milestone Uniqueness**: `UNIQUE(habit_id, milestone)` — one notification per habit per milestone

**Indexes:**

- `idx_milestone_notifications_habit_id` — retrieve notifications for a specific habit
- `idx_milestone_notifications_user_id` — retrieve all notifications for a user
- `idx_milestone_notifications_delivered` — filter undelivered notifications (for batch delivery jobs)
- `idx_milestone_notifications_read` — filter unread notifications (for user notification center)
- `idx_milestone_notifications_created_at` — sort notifications by creation time

**Design Notes:**

- Milestones are fixed at 3, 7, and 30 days to keep the feature simple and predictable
- One notification per milestone ensures users don't receive duplicate notifications
- `delivered` and `read` flags support notification delivery and read-receipt tracking
- Separate `delivered_at` and `read_at` timestamps enable monitoring notification delivery performance

---

### migrations

Tracks executed migrations to support schema versioning.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|-----------|---|
| id BIGSERIAL | PRIMARY KEY | Unique migration record identifier |
| name | VARCHAR(255) | NOT NULL, UNIQUE | Migration file name (e.g., "001_create_users_table") |
| executed_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Timestamp when migration was executed |

**Design Notes:**

- Automatically created by the migration runner
- Used to track which migrations have been applied to prevent running them multiple times
- Supports both forward and rollback operations

---

## Relationships

```
users (1) ←→ (many) habits
users (1) ←→ (many) check_ins
users (1) ←→ (many) milestone_notifications

habits (1) ←→ (many) check_ins
habits (1) ←→ (many) milestone_notifications
```

## Cascade Delete Behavior

Deleting a user cascades to:
1. All habits for that user
2. All check-ins for those habits
3. All milestone notifications for those habits

This ensures data consistency and prevents orphaned records.

## Query Patterns

### Get All Habits for a User

```sql
SELECT * FROM habits 
WHERE user_id = $1 
ORDER BY created_at DESC;
```

**Index Used**: `idx_habits_user_id`

### Get Active Habits

```sql
SELECT * FROM habits 
WHERE user_id = $1 AND status = 'ACTIVE'
ORDER BY name ASC;
```

**Indexes Used**: `idx_habits_user_id`, `idx_habits_status`

### Get Check-ins for a Date Range

```sql
SELECT * FROM check_ins 
WHERE habit_id = $1 
  AND check_in_date BETWEEN $2 AND $3
ORDER BY check_in_date ASC;
```

**Index Used**: `idx_check_ins_habit_date`

### Get Undelivered Notifications

```sql
SELECT * FROM milestone_notifications 
WHERE user_id = $1 AND delivered = FALSE
ORDER BY created_at DESC;
```

**Indexes Used**: `idx_milestone_notifications_user_id`, `idx_milestone_notifications_delivered`

## Enum Types

### habit_status

Represents the current state of a habit:

- `ACTIVE` — User is actively tracking this habit
- `PAUSED` — Habit is temporarily paused
- `ARCHIVED` — Habit is no longer active but preserved for history

## Migration Strategy

Migrations are located in `src/migrations/` and follow the pattern:

1. **Migration File**: Named sequentially (001, 002, 003, etc.)
2. **up() Function**: Defines schema changes (CREATE TABLE, ALTER TABLE, etc.)
3. **down() Function**: Reverses the up() operation (DROP TABLE, etc.)

The migration runner tracks executed migrations in the `migrations` table and only runs pending migrations.

### Running Migrations

```bash
npm run migrate
```

### Rolling Back Migrations

```bash
npm run migrate:rollback
```

## Testing Database Constraints

Comprehensive tests in `tests/unit/database.constraints.test.ts` validate:

- User provider tuple uniqueness
- Email uniqueness
- Habit name uniqueness per user
- Check-in uniqueness per habit per date
- Milestone value constraints (3, 7, 30 only)
- Milestone uniqueness per habit
- Date validation (no future dates)
- Foreign key constraints and cascade deletes
- Enum validation for habit status

Run tests with:

```bash
npm test -- database.constraints.test.ts
```

## Future Enhancements

1. **User Connections**: Add ability to link multiple OAuth providers to one account
2. **Categories**: Add habit categories (health, productivity, learning, etc.)
3. **Friends**: Add social features with friend requests and shared habits
4. **Statistics**: Add pre-computed statistics tables for performance
5. **Audit Logging**: Add audit table to track all data modifications
