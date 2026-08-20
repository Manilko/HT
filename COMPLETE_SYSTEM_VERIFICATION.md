# Complete System Verification Guide

## System Architecture

### Overview
- **Frontend:** Native iOS with SwiftUI and MVVM pattern
- **Backend:** Node.js/Express with TypeScript
- **Database:** PostgreSQL with migrations
- **Authentication:** OAuth 2.0 with JWT tokens
- **Real-time:** WebSocket for milestone notifications
- **Deployment:** Cloud-ready with Docker support

## Core Features Implemented

### 1. Authentication System ✓
- [x] OAuth SSO with Google and GitHub
- [x] JWT token generation (15m access, 7d refresh)
- [x] Automatic token refresh before expiry
- [x] Session restoration on app startup
- [x] Secure Keychain storage on iOS
- [x] 401 handling with automatic retry
- [x] Complete logout with state cleanup

**Key Endpoints:**
```
POST /v1/auth/google/callback        → Google OAuth exchange
POST /v1/auth/github/callback        → GitHub OAuth exchange
POST /v1/auth/refresh                → Token refresh
POST /v1/auth/logout                 → Session invalidation
```

**iOS Components:**
- `AuthService` — OAuth flow coordination
- `SessionManager` — Session lifecycle management
- `StorageManager` — Keychain token persistence
- `APIClient` — Token attachment and auto-refresh

### 2. Habit Management ✓
- [x] CRUD operations (Create, Read, Update, Delete)
- [x] Search and filtering by name/description
- [x] Status management (ACTIVE, PAUSED, ARCHIVED)
- [x] Streak calculation engine
- [x] User ownership verification

**Key Endpoints:**
```
GET /v1/habits                       → List habits with filters
GET /v1/habits/:id                   → Get habit details
POST /v1/habits                      → Create habit
PATCH /v1/habits/:id                 → Update habit
DELETE /v1/habits/:id                → Archive/delete habit
```

**Streak Algorithm:**
- Current streak: Consecutive days ending today (0 if gap)
- Best streak: Maximum historical consecutive sequence
- Never decreases based on later missed days
- Recalculated when today's check-in removed

### 3. Daily Check-ins ✓
- [x] One check-in per habit per day
- [x] Only today can be checked in
- [x] Paused/archived habits cannot be checked in
- [x] Undo today's check-in
- [x] Duplicate prevention with 409 Conflict

**Key Endpoints:**
```
POST /v1/habits/:habitId/check-ins   → Check in today
DELETE /v1/habits/:habitId/check-ins/today → Undo today
GET /v1/habits/:habitId/check-ins    → Get check-in history
```

**Business Rules:**
- Only ACTIVE habits accept check-ins
- One per habit per calendar date
- UNIQUE constraint: (habit_id, check_in_date)
- Check-in date enforced to today only
- Cross-user authorization verification

### 4. Streak Notifications ✓
- [x] WebSocket connections authenticated via JWT
- [x] Milestone tracking (3, 7, 30 days)
- [x] Delivery state persisted in database
- [x] No duplicate notifications after reconnect
- [x] In-app toast notifications
- [x] Automatic display without refresh

**WebSocket Flow:**
```
1. Client connects with JWT token
2. Client sends: { type: "subscribe", payload: { milestones: true } }
3. Server evaluates habits for milestones
4. Server sends: { type: "streak_milestone", payload: {...} }
5. Milestone delivery tracked in database
```

**Thresholds:** 3 days, 7 days, 30 days

### 5. UI/UX ✓
- [x] Modern light-mode-only design
- [x] Responsive SwiftUI layout
- [x] Consistent typography and spacing
- [x] Design tokens for centralized styling
- [x] Accessibility labels and hints
- [x] Loading, empty, and error states
- [x] Smooth animations and transitions
- [x] Toast notifications for milestones
- [x] Search and filtering UI

**Key Views:**
- `LoginView` — OAuth provider selection
- `DashboardView` — Main habits list with filters
- `HabitDetailView` — Full habit info and check-in control
- `SettingsView` — User settings and logout

## Testing Coverage

### Backend Tests

**Auth Routes (`tests/integration/auth.routes.test.ts`)**
```
✓ Google OAuth callback authenticates user
✓ Google OAuth callback creates new user
✓ Google OAuth callback reuses existing user
✓ GitHub OAuth callback authenticates user
✓ GitHub OAuth callback reuses existing user
✓ Token refresh returns new access token
✓ Token refresh fails with invalid refresh token
✓ Logout succeeds
✓ Missing code returns 400
✓ OAuth failure returns error
```

**Check-in Routes (`tests/integration/checkIns.routes.test.ts`)**
```
✓ Check in today returns 201
✓ Duplicate check-in returns 409
✓ Undo today's check-in returns 204
✓ Paused habit check-in returns 400
✓ Archived habit check-in returns 400
✓ Cross-user authorization fails
```

**Streak Calculation (`tests/unit/streakService.test.ts`, 50+ tests)**
```
✓ Zero check-ins: current=0, best=0
✓ Single check-in: current=1, best=1
✓ Consecutive days: current=N, best=N
✓ Gaps: current resets, best preserved
✓ May 1-3, May 5: current=0, best=3
✓ Removing today recalculates streak
✓ Edge cases with time zones
```

**WebSocket (`tests/unit/websocket.handler.test.ts`)**
```
✓ Authenticated connection succeeds
✓ Unauthenticated connection rejected
✓ Subscribe message handled
✓ Pending milestones sent on subscribe
✓ Invalid messages rejected
✓ User isolation enforced
```

**Milestone Service (`tests/unit/milestoneService.test.ts`)**
```
✓ 3-day milestone detected
✓ 7-day milestone detected
✓ 30-day milestone detected
✓ Archived habits skipped
✓ Already delivered milestones not sent
```

### iOS Tests

**Authentication (`HTTests/AuthenticationTests.swift`)**
```
✓ Session restoration with no tokens
✓ Session restoration with valid tokens
✓ Access token saved to Keychain
✓ Refresh token saved to Keychain
✓ Tokens cleared on logout
✓ Auth error displayed
✓ Cancelled auth error cleared
```

**Habits List (`HTTests/HabitListViewModelTests.swift`)**
```
✓ Load habits success
✓ Load habits error
✓ Check-in today success
✓ Check-in duplicate prevention
✓ Undo today's check-in
✓ Status filtering (active/paused/archived)
✓ Search filtering
✓ Error handling and storage
```

**WebSocket (`HTTests/WebSocketServiceTests.swift`)**
```
✓ Connection state management
✓ Subscribe/unsubscribe message format
✓ Milestone message decoding
✓ Error message handling
✓ Invalid message rejection
✓ Event stream exposure
✓ Graceful disconnect
✓ Missing/invalid token rejection
```

**Notifications (`HTTests/NotificationStoreTests.swift`)**
```
✓ Initial state correct
✓ Show notification
✓ Replace notification
✓ Dismiss notification
✓ Auto-dismiss timing
✓ Milestone notification types (3, 7, 30)
✓ Toast background colors
✓ Notification equality
```

**Logout (`HTTests/LogoutServiceTests.swift`)**
```
✓ Backend session invalidation
✓ Continues on backend error
✓ WebSocket disconnection
✓ Keychain cleanup (tokens)
✓ Keychain cleanup (user data)
✓ URLCache clearing
✓ Complete logout sequence
✓ No data remains after logout
```

## Deployment Checklist

### Prerequisites
- [ ] PostgreSQL database running
- [ ] Node.js 16+ installed
- [ ] npm/yarn/pnpm available
- [ ] iOS 15+ deployment target
- [ ] Xcode 14+ for iOS builds
- [ ] OAuth apps created (Google & GitHub)
- [ ] OAuth credentials obtained

### Backend Setup

**1. Environment Configuration**
```bash
# Copy example and fill in values
cp .env.example .env

# Set required variables:
DATABASE_URL=postgresql://...
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
JWT_SECRET=your-secret-key
NODE_ENV=production
```

**2. Database Setup**
```bash
npm run db:migrate    # Run migrations
npm run db:seed       # Optional: seed data
```

**3. Build Backend**
```bash
npm run build          # Compile TypeScript
npm run test          # Run all tests
npm start             # Start server
```

**Server should start at:**
```
http://localhost:3000
Health check: GET /health
```

### iOS Setup

**1. Configure OAuth Credentials**
```swift
// In AuthService.getClientId():
case "google": return "YOUR_GOOGLE_CLIENT_ID"
case "github": return "YOUR_GITHUB_CLIENT_ID"
```

**2. Update API Base URL**
```swift
// In APIClient:
private let baseURL = "https://api.habittracker.example/v1"
```

**3. Register Deep-Link Scheme**
- Already in Info.plist: `habittracker://oauth-callback`
- Verified in project configuration

**4. Build iOS App**
```bash
# Open in Xcode
open HT.xcodeproj

# Select target: HT
# Select destination: Simulator or Device
# Build and run
```

### Testing

**Backend Tests**
```bash
npm test                    # All tests
npm test -- --watch        # Watch mode
npm test auth.routes       # Auth tests only
npm test streakService     # Streak tests only
npm test websocket         # WebSocket tests only
```

**iOS Tests**
```bash
# In Xcode
Cmd+U                      # Run all tests
Cmd+Shift+U                # Run tests in scheme
Click specific test         # Run single test
```

## Verification Steps

### 1. Database Verification

Check PostgreSQL tables:
```bash
psql $DATABASE_URL
\dt                    # List tables

# Should have:
- users
- habits
- check_ins
- milestone_notifications
```

Verify migrations ran:
```sql
SELECT * FROM migrations;
-- Should see all migration files listed
```

### 2. Backend API Verification

Test auth endpoint:
```bash
curl -X POST http://localhost:3000/v1/auth/google/callback \
  -H "Content-Type: application/json" \
  -d '{"code": "test_code"}'

# Should return:
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "user": {...}
  },
  "timestamp": "..."
}
```

Test health endpoint:
```bash
curl http://localhost:3000/health
# Should return: { success: true }
```

### 3. iOS App Verification

**Launch App:**
- [ ] Starts without crash
- [ ] Shows LoginView with Google and GitHub buttons
- [ ] No authentication errors in console

**Sign In with Google:**
- [ ] Opens Safari browser
- [ ] Shows Google OAuth consent screen
- [ ] Returns to app with authorization code
- [ ] Exchanges code for tokens
- [ ] Saves tokens to Keychain
- [ ] Shows DashboardView

**Sign In with GitHub:**
- [ ] Opens Safari browser
- [ ] Shows GitHub authorization screen
- [ ] Returns to app
- [ ] Exchanges code for tokens
- [ ] Shows DashboardView

**Create Habit:**
- [ ] Navigate to create
- [ ] Enter name, description, date
- [ ] Submit
- [ ] Habit appears in list
- [ ] Displays correct streak values

**Check In:**
- [ ] View habit details
- [ ] See "Not completed today"
- [ ] Tap check-in button
- [ ] Shows loading state
- [ ] Updates to "Completed today"
- [ ] Streak updates

**Undo Check In:**
- [ ] Tap undo button
- [ ] Shows loading state
- [ ] Reverts to "Not completed today"
- [ ] Streak recalculates

**WebSocket Notifications:**
- [ ] Complete habits to reach 3-day milestone
- [ ] Toast notification appears
- [ ] Shows 🔥 3 day streak!
- [ ] Notification auto-dismisses

**Logout:**
- [ ] Go to Settings tab
- [ ] Tap Logout
- [ ] Confirm dialog
- [ ] Returns to LoginView
- [ ] No authenticated data visible

### 4. Security Verification

**Token Security:**
- [ ] Tokens stored in Keychain, not UserDefaults
- [ ] Tokens not logged or exposed
- [ ] No OAuth secrets in code
- [ ] Client secrets only on backend

**API Security:**
- [ ] All non-public endpoints require token
- [ ] Missing token returns 401
- [ ] Invalid token returns 401
- [ ] CORS properly configured
- [ ] SQL injection prevention (parameterized queries)

**Logout Security:**
- [ ] Keychain cleared completely
- [ ] WebSocket disconnected
- [ ] URLCache cleared
- [ ] No residual user data

## Performance Checklist

- [ ] App launch under 3 seconds
- [ ] Habit load under 1 second
- [ ] Check-in response under 500ms
- [ ] API requests include Authorization header
- [ ] No unauthorized API calls
- [ ] Token refresh happens silently
- [ ] WebSocket connects within 2 seconds
- [ ] Milestone notifications appear within 1 second
- [ ] No memory leaks on logout/login cycles

## Monitoring & Logging

**Backend Logs Should Show:**
```
[INFO] Server started on port 3000
[INFO] Database connected
[INFO] User authenticated: <user_id>
[INFO] Habit created: <habit_id>
[INFO] Check-in recorded: <habit_id>
[INFO] Milestone detected: <habit_id>, day <N>
[WARN] Token verification failed
[ERROR] Database error: ...
```

**iOS Logs Should Show:**
```
OAuth: exchanging code for tokens
TokenUtils: new token saved to Keychain
WebSocket: connected to milestone stream
Milestone received: 3 days!
Logout: clearing all tokens
```

## Common Issues & Solutions

### OAuth Flow Not Working
**Symptom:** "No authorization code received"
- [ ] Verify deep-link URL scheme in Info.plist
- [ ] Check OAuth app redirect URI matches
- [ ] Verify OAuth credentials are correct

### Tokens Not Persisting
**Symptom:** Logged out after app restart
- [ ] Check Keychain operations succeed
- [ ] Verify StorageManager methods called
- [ ] Ensure UserDefaults not blocking

### WebSocket Not Connecting
**Symptom:** Milestones never received
- [ ] Verify WebSocket endpoint accessible
- [ ] Check JWT token in connection URL
- [ ] Verify firewall allows WebSocket

### Streak Not Calculating
**Symptom:** Streaks always show 0
- [ ] Verify check-ins created in database
- [ ] Check streak calculation logic
- [ ] Verify timezone handling
- [ ] Test with known data

## Rollback Plan

If critical issues found:

**Backend:**
1. Revert last commit: `git revert HEAD`
2. Restart server: `npm start`
3. Migrations automatically applied

**iOS:**
1. Revert last commit: `git revert HEAD`
2. Rebuild in Xcode: `Cmd+B`
3. Delete app, reinstall from Xcode

## Next Steps

### Immediate (Production Ready)
1. Run full test suite locally
2. Verify all endpoints with Postman
3. Test OAuth flow end-to-end
4. Test on physical iOS device
5. Verify Keychain works on device
6. Test session restoration
7. Test logout completely

### Short Term (1-2 weeks)
1. Deploy backend to production
2. Configure production OAuth apps
3. Update iOS API base URL for production
4. Run smoke tests against production
5. Monitor logs for errors
6. Test auto-refresh with long sessions

### Medium Term (1 month)
1. Set up monitoring and alerting
2. Implement rate limiting
3. Add request logging/auditing
4. Performance optimization
5. Security audit
6. Load testing

## Documentation

- [OAUTH_IMPLEMENTATION_GUIDE.md](./OAUTH_IMPLEMENTATION_GUIDE.md) — OAuth system details
- [LOGOUT_GUIDE.md](./HT/Core/Authentication/LOGOUT_GUIDE.md) — Logout flow documentation
- [DESIGN_GUIDE.md](./HT/Design/DESIGN_GUIDE.md) — UI design system
- Backend README: Deployment instructions
- iOS README: Build and run instructions

## Support & Contact

For issues or questions:
1. Check logs: Backend console, Xcode console
2. Review test failures for details
3. Check documentation for known issues
4. Review git history for recent changes

## Final Verification

Run this checklist before marking complete:

- [ ] All backend tests pass: `npm test`
- [ ] All iOS tests pass: Cmd+U in Xcode
- [ ] No warnings in backend build
- [ ] No warnings in iOS build
- [ ] Code reviewed by team member
- [ ] Manual testing completed
- [ ] Documentation complete
- [ ] Security audit passed
- [ ] Performance benchmarks met
- [ ] Deployment plan documented

**System is production-ready when all items checked.**

