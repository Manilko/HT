# Habit Tracker - REST API Documentation

Base URL: `https://api.habittracker.example/v1`

## Authentication

All endpoints (except health check) require a Bearer token in the Authorization header:

```
Authorization: Bearer <access_token>
```

## Response Format

Success (200, 201):
```json
{
  "success": true,
  "data": {},
  "timestamp": "2026-08-20T10:30:00Z"
}
```

Error (4xx, 5xx):
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "details": {}
  },
  "timestamp": "2026-08-20T10:30:00Z"
}
```

## Endpoints

### Health Check

```
GET /health
```

Returns server status.

### Authentication

```
POST /auth/google/callback
POST /auth/github/callback
POST /auth/refresh
POST /auth/logout
```

See `AUTH.md` for detailed authentication flow.

### Habits

```
GET    /habits
POST   /habits
GET    /habits/:id
PATCH  /habits/:id
DELETE /habits/:id
GET    /habits/search?q=term
GET    /habits?status=active|archived
```

### Check-ins

```
GET    /habits/:id/check-ins?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD
POST   /habits/:id/check-in
DELETE /habits/:id/check-in/:date
```

### Streaks

```
GET    /habits/:id/streak
```

### Users

```
GET    /users/me
PATCH  /users/me
DELETE /users/me
```

## Error Codes

- `UNAUTHORIZED`: Missing or invalid authorization
- `FORBIDDEN`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `CONFLICT`: Resource conflict (e.g., duplicate)
- `INVALID_INPUT`: Validation error
- `INTERNAL_SERVER_ERROR`: Server error

## Rate Limiting

Not yet implemented. To be added based on deployment requirements.

## CORS

Configured per environment in `.env`

## Implementation Status

This documentation reflects the planned API. Endpoints are not yet implemented.
