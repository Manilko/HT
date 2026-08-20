# Check-ins API Documentation

## Overview

The Check-ins API provides RESTful endpoints for managing daily check-ins for habits. Check-ins track when users complete their habits on specific dates. All endpoints require authentication via JWT token.

## Base URL

```
/v1/habits/:habitId/check-ins
```

## Authentication

All requests must include a valid JWT token in the `Authorization` header:

```
Authorization: Bearer <JWT_TOKEN>
```

Users can only create, view, or undo check-ins for habits they own. Attempting to access another user's habits returns a 403 Forbidden error.

## Data Models

### CheckIn

```json
{
  "id": 456,
  "habitId": 123,
  "userId": 789,
  "checkInDate": "2026-08-20",
  "createdAt": "2026-08-20T10:30:00Z"
}
```

## Endpoints

### POST /v1/habits/:habitId/check-ins

Create a check-in for today.

**Request**

```
POST /v1/habits/123/check-ins
Authorization: Bearer <JWT_TOKEN>
```

**Response (201 Created)**

```json
{
  "success": true,
  "data": {
    "id": 456,
    "habitId": 123,
    "userId": 789,
    "checkInDate": "2026-08-20",
    "createdAt": "2026-08-20T10:30:00Z"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `201 Created` — Check-in created successfully
- `400 Bad Request` — Habit is not ACTIVE, or invalid habit ID
- `401 Unauthorized` — Missing or invalid JWT token
- `403 Forbidden` — Habit belongs to another user
- `404 Not Found` — Habit does not exist
- `409 Conflict` — User already checked in today for this habit

**Business Rules**

- Only habits with status ACTIVE can receive check-ins
- Users can only check in once per day per habit
- Check-ins can only be created for today (cannot create past/future check-ins)
- Check-ins are created atomically within a transaction

**Error Examples**

Duplicate check-in (already checked in today):

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Already checked in today for this habit"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

Habit not ACTIVE:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Habit is paused or archived and cannot accept check-ins"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

---

### GET /v1/habits/:habitId/check-ins

Get all check-ins for a habit.

**Request**

```
GET /v1/habits/123/check-ins
Authorization: Bearer <JWT_TOKEN>
```

**Response (200 OK)**

```json
{
  "success": true,
  "data": {
    "checkIns": [
      {
        "id": 456,
        "habitId": 123,
        "userId": 789,
        "checkInDate": "2026-08-20",
        "createdAt": "2026-08-20T10:30:00Z"
      },
      {
        "id": 457,
        "habitId": 123,
        "userId": 789,
        "checkInDate": "2026-08-19",
        "createdAt": "2026-08-19T09:15:00Z"
      }
    ],
    "count": 2
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `200 OK` — Check-ins retrieved successfully
- `401 Unauthorized` — Missing or invalid JWT token
- `403 Forbidden` — Habit belongs to another user
- `404 Not Found` — Habit does not exist

**Sorting**

Check-ins are returned in reverse chronological order (most recent first).

---

### DELETE /v1/habits/:habitId/check-ins/today

Undo today's check-in for a habit.

**Request**

```
DELETE /v1/habits/123/check-ins/today
Authorization: Bearer <JWT_TOKEN>
```

**Response (200 OK)**

```json
{
  "success": true,
  "data": { "id": 456 },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `200 OK` — Check-in deleted successfully
- `401 Unauthorized` — Missing or invalid JWT token
- `403 Forbidden` — Check-in belongs to another user
- `404 Not Found` — No check-in found for today

**Delete Behavior**

- Only the check-in for today (if it exists) is deleted
- User must own the habit to undo the check-in
- After undoing, the user can check in again today

---

## Authorization

### User Isolation

- Users can only create check-ins for habits they own
- Users can only view check-ins for habits they own
- Users can only undo check-ins they created
- Attempting to access another user's habit returns `403 Forbidden`

### Example

```
User A owns habit 123
User B makes POST /v1/habits/123/check-ins
→ 403 Forbidden (User B does not own habit 123)
```

## Business Rules

### Check-in Creation

1. **ACTIVE Habit Only** — Habit status must be ACTIVE
2. **Today Only** — Check-ins can only be created for today (CURRENT_DATE)
3. **One Per Day** — User cannot check in twice on the same day for the same habit
4. **No Future/Past** — Check-in dates must be today (cannot create backdated or future check-ins)
5. **User Ownership** — Check-in must belong to the authenticated user
6. **Atomic** — Check-in creation is transactional (all-or-nothing)

### Database Constraints

- **Unique Constraint**: `UNIQUE(habit_id, check_in_date)` ensures one check-in per habit per date
- **Foreign Key**: `habit_id` references `habits(id) ON DELETE CASCADE`
- **User Verification**: Check-in belongs to the user that owns the habit

### Duplicate Handling

If a check-in already exists for today:

- Status: `409 Conflict`
- Error Code: `INVALID_REQUEST`
- Message: "Already checked in today for this habit"
- Action: Existing check-in is preserved; new check-in is rejected

Duplicate check-ins must be handled idempotently at the API level:

1. Client requests POST /check-ins
2. Backend verifies UNIQUE constraint would be violated
3. Returns 409 before attempting INSERT
4. Idempotency: Retry does not corrupt data

### Streak Calculation (iOS/Client-side)

The backend does not compute streaks; the iOS client calculates them:

1. Fetch all check-ins for a habit via GET endpoint
2. Sort by check_in_date (ascending)
3. For each consecutive day with a check-in, increment current streak
4. Track the longest consecutive sequence as best streak
5. Current streak breaks if today (or yesterday) has no check-in

Example:

```
Check-in dates: 08-15, 08-16, 08-17, 08-19, 08-20
Current streak: 2 (08-19, 08-20)
Best streak: 3 (08-15 to 08-17)
Total check-ins: 5
```

## Error Handling

All errors follow a standard format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

### Common Error Codes

| Code | Status | Meaning |
|------|--------|---------|
| INVALID_REQUEST | 400 | Invalid input, habit not ACTIVE, or already checked in today |
| UNAUTHORIZED | 401 | Missing or invalid JWT token |
| FORBIDDEN | 403 | User does not own this habit or check-in |
| NOT_FOUND | 404 | Habit or check-in does not exist |
| INTERNAL_SERVER_ERROR | 500 | Server error |

## Response Format

All successful responses include:

```json
{
  "success": true,
  "data": { /* endpoint-specific data */ },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

## Testing

Run tests with:

```bash
npm test -- tests/integration/checkIns.routes.test.ts --forceExit
```

Test coverage includes:

- ✅ Today's check-in creation
- ✅ Duplicate check-in rejection (409)
- ✅ Undo today's check-in
- ✅ Paused habit rejection (400)
- ✅ Archived habit rejection (400)
- ✅ Future date rejection (not applicable; only today allowed)
- ✅ Past date rejection (not applicable; only today allowed)
- ✅ Cross-user authorization (403)
- ✅ Missing check-in on undo (404)
- ✅ User isolation

## Examples

### Daily Check-in Workflow

```bash
# 1. Get habit
HABIT_ID=123
TOKEN="eyJ..."

# 2. Check in for today
curl -X POST https://api.example.com/v1/habits/$HABIT_ID/check-ins \
  -H "Authorization: Bearer $TOKEN"

# Response: 201 Created with check-in data

# 3. View all check-ins
curl https://api.example.com/v1/habits/$HABIT_ID/check-ins \
  -H "Authorization: Bearer $TOKEN"

# 4. Undo today's check-in (if needed)
curl -X DELETE https://api.example.com/v1/habits/$HABIT_ID/check-ins/today \
  -H "Authorization: Bearer $TOKEN"

# Response: 200 OK

# 5. Check in again (after undo)
curl -X POST https://api.example.com/v1/habits/$HABIT_ID/check-ins \
  -H "Authorization: Bearer $TOKEN"
```

### Error Scenarios

```bash
# Already checked in today
curl -X POST https://api.example.com/v1/habits/123/check-ins \
  -H "Authorization: Bearer $TOKEN"

# Response: 409 Conflict
# { "error": { "code": "INVALID_REQUEST", "message": "Already checked in today..." } }

# Paused habit
curl -X POST https://api.example.com/v1/habits/124/check-ins \
  -H "Authorization: Bearer $TOKEN"

# Response: 400 Bad Request
# { "error": { "code": "INVALID_REQUEST", "message": "Habit is paused or archived..." } }
```

## Future Enhancements

- **Streak Notifications** — Notify user when streak reaches milestones (7, 30, 100 days)
- **Streak Freeze** — Allow users to freeze streak for planned breaks
- **Backfill Check-ins** — Ability to add check-ins for past dates (with fee or premium feature)
- **Bulk Operations** — Create/delete multiple check-ins in one request
- **Pagination** — Paginate large check-in lists
- **Filters** — Filter check-ins by date range
