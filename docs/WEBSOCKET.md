# WebSocket Protocol

## Connection

```
wss://api.habittracker.example/ws?token=ACCESS_TOKEN
```

Token is passed as query parameter on initial connection.

## Authentication

Server validates the JWT token and closes the connection if invalid.

## Client → Server Events

### Subscribe to Milestone

```json
{
  "type": "subscribe_milestone",
  "data": {
    "habit_id": 123
  }
}
```

### Unsubscribe from Milestone

```json
{
  "type": "unsubscribe_milestone",
  "data": {
    "habit_id": 123
  }
}
```

### Ping

```json
{
  "type": "ping"
}
```

## Server → Client Events

### Milestone Reached

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
```

### Pong

```json
{
  "type": "pong"
}
```

### Error

```json
{
  "type": "error",
  "data": {
    "code": "UNAUTHORIZED",
    "message": "Token expired"
  }
}
```

## Reconnection

Client should implement exponential backoff:
- 1s, 2s, 4s, 8s, 30s (max)
- Max 5 attempts before user notification

After reconnection, resubscribe to all habits.

## Implementation Status

WebSocket structure is defined. Implementation coming soon.
