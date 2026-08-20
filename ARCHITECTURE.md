# Habit Tracker - Technical Architecture

## Executive Summary

This document proposes a complete architecture for a native iOS application with a Node.js/TypeScript backend for managing user habits with OAuth/OIDC authentication (Google, GitHub), real-time streak notifications, and comprehensive data privacy controls.

---

## 1. Requirements Analysis

### Functional Requirements
- **User Management**: Multi-user system with Google/GitHub SSO
- **Habits**: Create, read, update, delete habits (CRUD)
- **Check-ins**: Log daily habit completions
- **Streaks**: Track current streak, best streak, total check-ins per habit
- **Search & Filters**: Find habits by name, filter by status
- **Real-time Notifications**: WebSocket-based milestone notifications (streak milestones)
- **Privacy**: Complete data isolation per user

### Technical Requirements
- OAuth/OIDC (Google, GitHub)
- Timezone-aware streak calculations
- Automated tests (backend + iOS)
- WebSocket for real-time features

### Identified Ambiguities & Risks
1. **Streak Definition**: Does a "day" reset at midnight in user's timezone or UTC?
   - **Risk**: Inconsistent streak counts across timezones
   - **Decision**: Use user's timezone for all date boundaries

2. **Check-in Frequency**: Can users check-in multiple times per day?
   - **Risk**: Undefined behavior if allowing multiple check-ins
   - **Decision**: One check-in per day per habit; future check-ins are no-ops

3. **Milestone Notifications**: Which milestones trigger WebSocket events? (every day, 7-day, 30-day, 100-day?)
   - **Risk**: Backend spam or underutilized feature
   - **Decision**: Configurable milestones (7, 14, 30, 50, 100+ days)

4. **Deleted Habits**: Should they be soft-deleted or hard-deleted?
   - **Risk**: Data loss vs. keeping historical data
   - **Decision**: Soft-delete with archival; check-ins remain for history

5. **Offline Support**: Should iOS cache data locally?
   - **Risk**: Stale data conflicts
   - **Decision**: Fetch on app launch; no offline mode for MVP

6. **Token Refresh**: How are tokens managed long-term?
   - **Risk**: Token expiration, refresh token rotation
   - **Decision**: Refresh token in secure Keychain; rotate on use

---

## 2. Repository Folder Structure

```
habit-tracker/
├── ios/                           # iOS app
│   ├── HT/
│   │   ├── App/
│   │   │   ├── HTApp.swift        # App entry point
│   │   │   └── AppCoordinator.swift
│   │   ├── Scenes/
│   │   │   ├── Auth/
│   │   │   │   ├── AuthView.swift
│   │   │   │   ├── AuthViewModel.swift
│   │   │   │   └── AuthCoordinator.swift
│   │   │   ├── Habits/
│   │   │   │   ├── HabitsListView.swift
│   │   │   │   ├── HabitsListViewModel.swift
│   │   │   │   ├── HabitsCoordinator.swift
│   │   │   │   ├── HabitDetailView.swift
│   │   │   │   └── HabitDetailViewModel.swift
│   │   │   ├── CheckIn/
│   │   │   │   ├── CheckInView.swift
│   │   │   │   └── CheckInViewModel.swift
│   │   │   └── Settings/
│   │   │       ├── SettingsView.swift
│   │   │       └── SettingsViewModel.swift
│   │   ├── Services/
│   │   │   ├── APIService.swift       # REST API client
│   │   │   ├── WebSocketService.swift # WebSocket manager
│   │   │   ├── AuthService.swift      # OAuth/OIDC flow
│   │   │   ├── KeychainService.swift  # Token storage
│   │   │   └── HabitService.swift     # Business logic
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   ├── Habit.swift
│   │   │   ├── CheckIn.swift
│   │   │   ├── Streak.swift
│   │   │   └── DTOs.swift             # API request/response models
│   │   ├── Utilities/
│   │   │   ├── Extensions.swift
│   │   │   └── Constants.swift
│   │   └── Assets.xcassets/
│   ├── HTTests/
│   │   ├── Services/
│   │   │   ├── APIServiceTests.swift
│   │   │   ├── AuthServiceTests.swift
│   │   │   └── WebSocketServiceTests.swift
│   │   ├── ViewModels/
│   │   │   ├── HabitsListViewModelTests.swift
│   │   │   └── AuthViewModelTests.swift
│   │   └── Mocks/
│   │       ├── MockAPIService.swift
│   │       └── MockWebSocketService.swift
│   └── HT.xcodeproj/
│
├── backend/                       # Node.js backend
│   ├── src/
│   │   ├── app.ts                 # Express app setup
│   │   ├── server.ts              # Entry point with WebSocket
│   │   ├── config/
│   │   │   ├── database.ts        # PostgreSQL connection
│   │   │   ├── auth.ts            # OAuth config
│   │   │   └── env.ts             # Environment variables
│   │   ├── auth/
│   │   │   ├── oauth.controller.ts
│   │   │   ├── oauth.service.ts
│   │   │   ├── jwt.service.ts
│   │   │   └── middleware.ts      # Auth guards
│   │   ├── habits/
│   │   │   ├── habits.controller.ts
│   │   │   ├── habits.service.ts
│   │   │   ├── habits.repository.ts
│   │   │   ├── streak.service.ts
│   │   │   └── habit.schema.ts    # Validation
│   │   ├── check-ins/
│   │   │   ├── check-ins.controller.ts
│   │   │   ├── check-ins.service.ts
│   │   │   ├── check-ins.repository.ts
│   │   │   └── check-in.schema.ts
│   │   ├── users/
│   │   │   ├── users.service.ts
│   │   │   ├── users.repository.ts
│   │   │   └── user.schema.ts
│   │   ├── websocket/
│   │   │   ├── websocket.gateway.ts  # WebSocket handlers
│   │   │   ├── notifications.service.ts
│   │   │   └── events.ts
│   │   ├── middleware/
│   │   │   ├── errorHandler.ts
│   │   │   ├── requestLogger.ts
│   │   │   └── cors.ts
│   │   ├── utils/
│   │   │   ├── dateUtils.ts       # Timezone handling
│   │   │   ├── streakCalculator.ts
│   │   │   └── logger.ts
│   │   └── types/
│   │       └── index.ts           # TypeScript types
│   ├── tests/
│   │   ├── unit/
│   │   │   ├── habits.service.test.ts
│   │   │   ├── streak.service.test.ts
│   │   │   └── auth.service.test.ts
│   │   ├── integration/
│   │   │   ├── habits.routes.test.ts
│   │   │   ├── check-ins.routes.test.ts
│   │   │   └── auth.routes.test.ts
│   │   └── fixtures/
│   │       └── testData.ts
│   ├── migrations/
│   │   ├── 001_create_users_table.ts
│   │   ├── 002_create_habits_table.ts
│   │   ├── 003_create_check_ins_table.ts
│   │   └── 004_indexes.ts
│   ├── .env.example
│   ├── package.json
│   ├── tsconfig.json
│   ├── jest.config.js
│   └── README.md
│
└── docs/
    ├── API.md                     # API documentation
    ├── WEBSOCKET.md               # WebSocket protocol
    ├── AUTH.md                    # Authentication flow
    ├── DATABASE.md                # Schema & queries
    └── DEPLOYMENT.md
```

---

## 3. Database Schema

### PostgreSQL Schema

```sql
-- Users table
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  oauth_id VARCHAR(255) UNIQUE NOT NULL,  -- Google/GitHub user ID
  oauth_provider ENUM('google', 'github') NOT NULL,
  timezone VARCHAR(50) DEFAULT 'UTC',
  profile_picture_url TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP  -- Soft delete
);

-- Habits table
CREATE TABLE habits (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  color VARCHAR(7),  -- Hex color
  frequency VARCHAR(50) DEFAULT 'daily',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP,  -- Soft delete for history
  UNIQUE(user_id, name),  -- User can't have duplicate habit names
  CHECK (frequency IN ('daily', 'weekly'))
);

-- Check-ins table
CREATE TABLE check_ins (
  id BIGSERIAL PRIMARY KEY,
  habit_id BIGINT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  check_in_date DATE NOT NULL,  -- In user's timezone
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(habit_id, check_in_date)  -- One check-in per day per habit
);

-- Streaks (denormalized for performance)
CREATE TABLE streaks (
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

-- Indexes
CREATE INDEX idx_users_oauth_id ON users(oauth_id);
CREATE INDEX idx_habits_user_id ON habits(user_id);
CREATE INDEX idx_habits_deleted ON habits(deleted_at);
CREATE INDEX idx_check_ins_habit_id ON check_ins(habit_id);
CREATE INDEX idx_check_ins_user_id ON check_ins(user_id);
CREATE INDEX idx_check_ins_date ON check_ins(check_in_date);
CREATE INDEX idx_streaks_habit_id ON streaks(habit_id);
```

### Key Design Decisions
- **Streaks table**: Denormalized for O(1) queries; updated transactionally with check-ins
- **Soft deletes**: `deleted_at` field preserves data history
- **User timezone**: Stored per user; all date logic uses this
- **Check-in date**: Stored as DATE (no time component) in user's timezone

---

## 4. REST API Endpoints

### Base URL: `https://api.habittracker.example/v1`

#### Authentication
```
POST   /auth/google/callback        # Exchange Google auth code for tokens
POST   /auth/github/callback        # Exchange GitHub auth code for tokens
POST   /auth/refresh                # Refresh access token
POST   /auth/logout                 # Invalidate refresh token
```

#### Habits
```
GET    /habits                      # List user's habits (with current streak)
POST   /habits                      # Create habit
GET    /habits/:id                  # Get habit detail with streak
PATCH  /habits/:id                  # Update habit
DELETE /habits/:id                  # Soft delete habit

GET    /habits/search?q=term        # Search habits by name
GET    /habits?status=active        # Filter habits (active, archived)
```

#### Check-ins
```
GET    /habits/:id/check-ins?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
POST   /habits/:id/check-in         # Log today's check-in
DELETE /habits/:id/check-in/:date   # Remove specific check-in
```

#### Streaks
```
GET    /habits/:id/streak           # Get streak data (current, best, total)
```

#### Users
```
GET    /users/me                    # Get current user profile
PATCH  /users/me                    # Update user timezone, display name
DELETE /users/me                    # Delete account (hard delete all data)
```

### Response Format

```typescript
// Success (200, 201)
{
  success: true,
  data: { /* resource */ },
  timestamp: "2026-08-20T10:30:00Z"
}

// Error (4xx, 5xx)
{
  success: false,
  error: {
    code: "HABIT_NOT_FOUND",
    message: "Habit with ID 123 not found",
    details: {}
  },
  timestamp: "2026-08-20T10:30:00Z"
}
```

---

## 5. WebSocket Protocol

### Connection
```
wss://api.habittracker.example/ws?token=ACCESS_TOKEN
```

### Authentication
- Token passed as query parameter (initial connection)
- Server validates token; closes connection if invalid

### Events

#### Client → Server
```json
{
  "type": "subscribe_milestone",
  "data": {
    "habit_id": 123
  }
}

{
  "type": "unsubscribe_milestone",
  "data": {
    "habit_id": 123
  }
}

{
  "type": "ping"
}
```

#### Server → Client
```json
{
  "type": "milestone_reached",
  "data": {
    "habit_id": 123,
    "habit_name": "Morning Run",
    "current_streak": 30,
    "milestone": 30
  },
  "timestamp": "2026-08-20T10:30:00Z"
}

{
  "type": "pong"
}

{
  "type": "error",
  "data": {
    "code": "UNAUTHORIZED",
    "message": "Token expired"
  }
}
```

### Reconnection Strategy
- Exponential backoff (1s, 2s, 4s, 8s, 30s max)
- Max 5 retry attempts before user notification
- Resubscribe to all habits on successful reconnect

---

## 6. Authentication Architecture

### OAuth/OIDC Flow (Google & GitHub)

#### Step 1: iOS Initiates Login
1. User taps "Sign in with Google" / "Sign in with GitHub"
2. iOS opens ASWebAuthenticationSession (system browser)
3. Redirects to: `https://api.habittracker.example/v1/auth/{provider}/authorize`

#### Step 2: Backend Initiates OAuth
- Backend redirects to Google/GitHub consent screen with:
  - `client_id`
  - `redirect_uri`: `https://api.habittracker.example/v1/auth/{provider}/callback`
  - `scope`: `openid profile email`
  - `state`: CSRF token (random, stored in session/Redis)

#### Step 3: User Authorizes
- User grants permissions on Google/GitHub
- Google/GitHub redirects to backend callback with authorization code

#### Step 4: Backend Exchanges Code
```typescript
// Backend receives: code, state
// 1. Verify state matches stored CSRF token
// 2. Exchange code for ID token + access token with Google/GitHub
// 3. Verify ID token signature
// 4. Extract user info (email, name, picture, oauth_id)
// 5. Create or update user in database
// 6. Generate JWT access token (15 min expiry)
// 7. Generate refresh token (7 day expiry, stored in Keychain)
// 8. Redirect to iOS app via custom scheme: habittracker://auth/success?access_token=...&refresh_token=...
```

#### Step 5: iOS Stores Tokens
```swift
// Store in Keychain (secure, encrypted)
- accessToken (15 min validity)
- refreshToken (7 day validity)
- user profile (cache)
```

### JWT Claims
```json
{
  "sub": "user_id_123",
  "email": "user@example.com",
  "oauth_provider": "google",
  "oauth_id": "google_user_id",
  "iat": 1692518400,
  "exp": 1692519300,
  "aud": "ios-app"
}
```

### Refresh Token Rotation
- Backend issues new refresh token with each refresh
- Old refresh token invalidated immediately
- If old token used again → suspicious activity → invalidate all tokens, require re-login

---

## 7. Streak Calculation

### Algorithm

```
For each habit:
1. Get all check-ins sorted by date (DESC)
2. Determine user's timezone from user profile
3. Calculate "today" in user's timezone

Current Streak:
- Start from today's date
- Traverse backwards through check-in dates
- Count consecutive days with check-ins
- Stop at first gap
- Return count

Best Streak:
- Traverse all check-in dates (DESC)
- Track longest consecutive sequence
- Return count + start_date + end_date

Total Check-ins:
- Count all check-ins for habit (count(*))
```

### Example
```
Check-ins: 2026-08-15, 2026-08-14, 2026-08-13, 2026-08-10, 2026-08-09
Today: 2026-08-15 (user's timezone)

Current streak: 3 days (15, 14, 13)
Best streak: 3 days (15-13) with previous best 2 days (10-09)
Total: 5 check-ins
```

### Edge Cases
- **Missed today**: Current streak preserved if checked in yesterday; resets if missed today
- **Timezone boundaries**: Always use user's timezone for date calculations
- **DST transitions**: Use standard library (e.g., `date-fns-tz`) to handle DST correctly

---

## 8. Timezone Handling

### Strategy
- Store user's IANA timezone (e.g., "America/New_York")
- All check-in dates stored as DATE (no time) in user's timezone
- Backend converts UTC timestamps to user timezone before date logic

### Implementation
```typescript
// Backend utility
import { utcToZonedTime, zonedTimeToUtc } from 'date-fns-tz';

// Get "today" in user's timezone
function getTodayInUserTz(userTimezone: string): Date {
  return utcToZonedTime(new Date(), userTimezone).toDateString();
}

// Check-in submitted with timestamp
function processCheckIn(userTimezone: string, timestamp: Date): string {
  const zonedDate = utcToZonedTime(timestamp, userTimezone);
  return zonedDate.toISOString().split('T')[0];  // YYYY-MM-DD
}
```

### iOS Side
- Store timezone as user property (from profile or device settings)
- Pass with every check-in request: `POST /habits/:id/check-in { timezone: "America/New_York" }`

---

## 9. iOS Authentication Flow

### Implementation Using ASWebAuthenticationSession

```swift
// 1. User taps "Sign in with Google"
// 2. Generate PKCE parameters (code_challenge, code_verifier)
// 3. Open system browser:
let url = URL(string: "https://api.habittracker.example/v1/auth/google/authorize?...")!
let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "habittracker") { callbackURL, error in
    // 4. Browser closes, callbackURL contains auth code
    // 5. Exchange code for tokens via POST /auth/google/callback
    // 6. Extract access_token, refresh_token, user_id from response
    // 7. Store tokens in Keychain
    // 8. Navigate to main app
}

// Keychain storage
KeychainService.save(key: "accessToken", value: accessToken)
KeychainService.save(key: "refreshToken", value: refreshToken)
```

### Token Refresh on App Launch
```swift
// On app launch:
// 1. Retrieve accessToken and refreshToken from Keychain
// 2. Check if accessToken expired (compare iat + 900 < now)
// 3. If expired, POST /auth/refresh { refreshToken }
// 4. Receive new accessToken, refreshToken
// 5. Update Keychain
// 6. Navigate to main app
// 7. If refresh fails, navigate to login
```

---

## 10. Backend Authorization (Data Privacy)

### Principles
1. **Every API request requires authentication** (valid JWT in Authorization header)
2. **Extract `sub` (user_id) from JWT** and validate on every operation
3. **Query filtering**: Always append `AND user_id = $1` to queries
4. **Row-level security**: Explicitly fetch user_id before returning resource

### Implementation

```typescript
// Middleware: Extract and validate JWT
export async function authMiddleware(req, res, next) {
  const token = req.headers.authorization?.replace('Bearer ', '');
  const payload = verifyJWT(token);  // Throws if invalid
  req.userId = payload.sub;
  next();
}

// Service: Fetch habit with user validation
async function getHabit(habitId: number, userId: number) {
  const habit = await db.query(
    'SELECT * FROM habits WHERE id = $1 AND user_id = $2',
    [habitId, userId]
  );
  if (!habit) throw new Error('NOT_FOUND');
  return habit;
}

// Controller
router.get('/habits/:id', authMiddleware, async (req, res) => {
  const habit = await habitService.getHabit(req.params.id, req.userId);
  res.json(habit);
});
```

### Prevents
- ✅ User A accessing User B's habits
- ✅ User A modifying User B's streaks
- ✅ User A deleting User B's check-ins
- ✅ User A impersonating User B (token forgery)

---

## 11. Testing Strategy

### iOS Testing

#### Unit Tests (XCTest)
- `HabitsListViewModelTests`: Test filtering, sorting, search
- `AuthViewModelTests`: Test login flow, token storage
- `KeychainServiceTests`: Test token encryption/retrieval
- `StreakCalculatorTests`: Test streak logic with various date inputs

#### Integration Tests
- `APIServiceTests`: Mock URLSession, test API calls
- `WebSocketServiceTests`: Test WebSocket connection, reconnection, message handling

#### UI Tests (if time permits)
- Login flow
- Create habit
- Check-in flow

### Backend Testing

#### Unit Tests (Jest)
- `streak.service.test.ts`: Streak calculation logic with edge cases
- `auth.service.test.ts`: Token generation, refresh token rotation
- `users.repository.test.ts`: Database queries with user isolation

#### Integration Tests
- `POST /auth/google/callback`: Full OAuth flow simulation
- `POST /habits`: Create habit, verify in database
- `POST /habits/:id/check-in`: Log check-in, verify streak updated
- `GET /habits/:id`: Verify user can't access other user's habit

#### End-to-End Tests
- Complete flow: Login → Create Habit → Daily Check-ins → Streak Growth

#### Test Data
- Fixtures with various timezones, DST boundaries
- Edge cases: Month boundaries, year boundaries, leap years

---

## 12. Technical Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Token expiration during app use | User suddenly logged out | Auto-refresh tokens on 401, with user notification |
| Timezone bugs causing wrong dates | Streaks calculated incorrectly | Comprehensive timezone tests, use battle-tested libraries |
| WebSocket connection drops | Missed milestone notifications | Auto-reconnect with exponential backoff |
| Concurrent check-ins | Duplicate streaks updated | DB unique constraint on (habit_id, check_in_date) |
| OAuth provider downtime | Users can't log in | Fallback to email/password (future) or graceful error messages |
| Large habit lists | Slow pagination | Limit to 100 habits per request, add pagination cursor |
| Database performance | Slow queries on large datasets | Index on (user_id, habit_id), denormalized streaks table |

---

## Approval Checklist

- [ ] Folder structure acceptable?
- [ ] Database schema covers requirements?
- [ ] API endpoints complete?
- [ ] WebSocket protocol clear?
- [ ] Authentication flow secure and clear?
- [ ] Authorization logic prevents cross-user access?
- [ ] Streak calculation algorithm correct?
- [ ] Timezone handling approach sound?
- [ ] Testing strategy comprehensive?
- [ ] Any missing features or unclear areas?

**Please review and provide feedback before implementation begins.**
