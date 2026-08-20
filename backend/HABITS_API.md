# Habits API Documentation

## Overview

The Habits API provides RESTful endpoints for managing user habits. All endpoints require authentication via JWT token.

## Base URL

```
/v1/habits
```

## Authentication

All requests must include a valid JWT token in the `Authorization` header:

```
Authorization: Bearer <JWT_TOKEN>
```

Users can only access their own habits. Attempting to access another user's habits returns a 403 Forbidden error.

## Data Models

### Habit

```json
{
  "id": 123,
  "name": "Morning Run",
  "description": "Run 5 miles every morning",
  "startDate": "2026-08-20",
  "status": "ACTIVE",
  "createdAt": "2026-08-20T10:30:00Z",
  "updatedAt": "2026-08-20T10:30:00Z"
}
```

### Status

- **ACTIVE** — Habit is currently active and user is tracking check-ins
- **PAUSED** — Habit is temporarily paused; user can resume later
- **ARCHIVED** — Habit is archived; no longer active but data is preserved

## Endpoints

### GET /v1/habits

List all habits for the authenticated user.

**Request**

```
GET /v1/habits
Authorization: Bearer <JWT_TOKEN>
```

**Response**

```json
{
  "success": true,
  "data": {
    "habits": [
      {
        "id": 1,
        "name": "Morning Run",
        "description": "Run 5 miles",
        "startDate": "2026-08-20",
        "status": "ACTIVE",
        "createdAt": "2026-08-20T10:30:00Z",
        "updatedAt": "2026-08-20T10:30:00Z"
      }
    ],
    "count": 1
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `200 OK` — Habits retrieved successfully
- `401 Unauthorized` — Missing or invalid JWT token

---

### GET /v1/habits/:id

Get a specific habit by ID.

**Request**

```
GET /v1/habits/123
Authorization: Bearer <JWT_TOKEN>
```

**Response**

```json
{
  "success": true,
  "data": {
    "id": 123,
    "name": "Morning Run",
    "description": "Run 5 miles",
    "startDate": "2026-08-20",
    "status": "ACTIVE",
    "createdAt": "2026-08-20T10:30:00Z",
    "updatedAt": "2026-08-20T10:30:00Z"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `200 OK` — Habit retrieved successfully
- `400 Bad Request` — Invalid habit ID format
- `401 Unauthorized` — Missing or invalid JWT token
- `403 Forbidden` — Habit belongs to another user
- `404 Not Found` — Habit does not exist

---

### POST /v1/habits

Create a new habit.

**Request**

```
POST /v1/habits
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "name": "Morning Run",
  "description": "Run 5 miles every morning",
  "startDate": "2026-08-20"
}
```

**Request Fields**

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| name | string | Yes | 1-255 characters, must be unique per user |
| description | string | No | Max 1000 characters |
| startDate | date | Yes | YYYY-MM-DD format, cannot be in future |

**Response**

```json
{
  "success": true,
  "data": {
    "id": 123,
    "name": "Morning Run",
    "description": "Run 5 miles every morning",
    "startDate": "2026-08-20",
    "status": "ACTIVE",
    "createdAt": "2026-08-20T10:30:00Z",
    "updatedAt": "2026-08-20T10:30:00Z"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `201 Created` — Habit created successfully
- `400 Bad Request` — Invalid input (see error message for details)
- `401 Unauthorized` — Missing or invalid JWT token

**Error Examples**

Missing name:
```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Habit name is required"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

Duplicate habit name:
```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Unique constraint violation"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

---

### PATCH /v1/habits/:id

Update an existing habit.

**Request**

```
PATCH /v1/habits/123
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "name": "Evening Run",
  "status": "PAUSED"
}
```

**Request Fields** (all optional)

| Field | Type | Constraints |
|-------|------|-------------|
| name | string | 1-255 characters, must be unique per user |
| description | string | Max 1000 characters, null to clear |
| status | string | ACTIVE, PAUSED, or ARCHIVED (see status transitions) |

**Response**

```json
{
  "success": true,
  "data": {
    "id": 123,
    "name": "Evening Run",
    "description": "Run 5 miles every morning",
    "startDate": "2026-08-20",
    "status": "PAUSED",
    "createdAt": "2026-08-20T10:30:00Z",
    "updatedAt": "2026-08-20T10:35:00Z"
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `200 OK` — Habit updated successfully
- `400 Bad Request` — Invalid input or invalid status transition
- `401 Unauthorized` — Missing or invalid JWT token
- `403 Forbidden` — Habit belongs to another user
- `404 Not Found` — Habit does not exist

**Status Transition Rules**

Valid transitions:

```
ACTIVE  → PAUSED
ACTIVE  → ARCHIVED
PAUSED  → ACTIVE
PAUSED  → ARCHIVED
```

Invalid transitions (return 400):

```
ARCHIVED → ACTIVE
ARCHIVED → PAUSED
```

**Archived Habit Rules**

- Archived habits are read-only
- Cannot update name or description of archived habits
- Can only change status out of archived state (not possible by design)
- Check-ins cannot be added to archived habits (validation in check-ins API)

---

### DELETE /v1/habits/:id

Delete a habit (must be archived first).

**Request**

```
DELETE /v1/habits/123
Authorization: Bearer <JWT_TOKEN>
```

**Response**

```json
{
  "success": true,
  "data": {
    "id": 123
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

**Status Codes**

- `200 OK` — Habit deleted successfully
- `400 Bad Request` — Habit is not archived
- `401 Unauthorized` — Missing or invalid JWT token
- `403 Forbidden` — Habit belongs to another user
- `404 Not Found` — Habit does not exist

**Delete Behavior**

When a habit is deleted:

1. **Transaction**: Operation is atomic (all-or-nothing)
2. **Cascade Delete**: All check-ins for the habit are deleted
3. **Cascade Delete**: All milestone notifications for the habit are deleted
4. **Requirement**: Habit must be archived first to prevent accidental loss of active habits
5. **Data Loss**: Deletion is permanent and cannot be undone

Example error if habit is not archived:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Only archived habits can be deleted. Archive the habit first."
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

## Authorization

### User Isolation

- Users can only access (read, update, delete) habits they own
- Attempting to access another user's habit returns `403 Forbidden`
- Habit ownership is determined by the `user_id` field in the database

### Example

```
User A creates habit 123
User B makes GET /v1/habits/123
→ 403 Forbidden (User B does not own habit 123)
```

## Validation Rules

### Habit Name

- **Required**: Yes
- **Type**: String
- **Length**: 1-255 characters
- **Whitespace**: Trimmed before storage
- **Uniqueness**: Must be unique per user (same user cannot have two habits with identical names)
- **Empty**: Cannot be empty after trimming

Example error:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Habit name is required"
  }
}
```

### Description

- **Required**: No
- **Type**: String or null
- **Length**: Max 1000 characters
- **Whitespace**: Trimmed before storage
- **Null**: Allowed (use to clear description)

### Start Date

- **Required**: Yes
- **Format**: YYYY-MM-DD (ISO 8601)
- **Constraint**: Must not be in the future
- **Constraint**: Must be valid date

Example error for future date:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Start date cannot be in the future"
  }
}
```

## Error Handling

All errors follow a standard format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  },
  "timestamp": "2026-08-20T12:00:00Z"
}
```

### Common Error Codes

| Code | Status | Meaning |
|------|--------|---------|
| INVALID_REQUEST | 400 | Invalid input or request parameters |
| UNAUTHORIZED | 401 | Missing or invalid JWT token |
| FORBIDDEN | 403 | Access denied (not your habit) |
| NOT_FOUND | 404 | Habit does not exist |
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

## Rate Limiting

Not currently implemented. Future versions may include rate limiting per authenticated user.

## Pagination

List endpoint (`GET /v1/habits`) currently returns all habits. Future versions may implement pagination with limit/offset parameters.

## Examples

### Create and Archive a Habit

```bash
# 1. Create habit
curl -X POST https://api.example.com/v1/habits \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Morning Run",
    "description": "Run 5 miles",
    "startDate": "2026-08-20"
  }'

# Response includes: { "data": { "id": 123, "status": "ACTIVE", ... } }

# 2. Pause the habit
curl -X PATCH https://api.example.com/v1/habits/123 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "status": "PAUSED" }'

# 3. Archive the habit
curl -X PATCH https://api.example.com/v1/habits/123 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "status": "ARCHIVED" }'

# 4. Delete the habit
curl -X DELETE https://api.example.com/v1/habits/123 \
  -H "Authorization: Bearer $TOKEN"
```

### List Habits

```bash
curl https://api.example.com/v1/habits \
  -H "Authorization: Bearer $TOKEN"
```

## Testing

Run tests with:

```bash
npm test -- habits.routes.test.ts --forceExit
```

Test coverage:

- ✅ Create habit with all fields
- ✅ Create habit with required fields only
- ✅ Prevent duplicate habit names per user
- ✅ Allow same habit name for different users
- ✅ Validate all input fields
- ✅ Get single habit (owner access)
- ✅ Get single habit (deny other users)
- ✅ List habits (user isolation)
- ✅ Update habit (all fields)
- ✅ Prevent modification of archived habits
- ✅ Archive habit
- ✅ Delete archived habit
- ✅ Prevent deletion of non-archived habits
- ✅ Status transitions (valid and invalid)
- ✅ Authorization checks (403 for other users)
