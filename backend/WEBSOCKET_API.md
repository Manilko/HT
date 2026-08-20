# WebSocket Milestone Notifications API

## Overview

The Habit Tracker WebSocket API provides real-time milestone notifications for habits. When a user's habit streak reaches a milestone (3, 7, or 30 consecutive days), they receive a notification via WebSocket.

## Connection

### Endpoint

```
ws://api.example.com/api/ws?token=<JWT_TOKEN>
```

### Authentication

The WebSocket connection requires a valid JWT token passed as a query parameter. The token is extracted and verified on connection:

```javascript
const token = localStorage.getItem('accessToken');
const ws = new WebSocket(`ws://api.example.com/api/ws?token=${token}`);
```

**Important**: The user ID is extracted from the JWT token, never accepted directly from the client. This ensures proper authorization.

### Connection Lifecycle

1. Client connects with valid JWT token
2. Server verifies token and authenticates user
3. Connection established with user context
4. Server maintains subscription state per connection
5. Milestones are delivered and tracked per habit

## Message Format

### Client -> Server

All messages must be valid JSON with a `type` field:

```json
{
  "type": "subscribe",
  "payload": {
    "milestones": true
  }
}
```

### Server -> Client

#### Milestone Notification

Sent when a habit reaches a milestone:

```json
{
  "type": "streak_milestone",
  "payload": {
    "habitId": 123,
    "habitName": "Morning Run",
    "milestone": 3,
    "currentStreak": 3
  }
}
```

#### Error Message

Sent when an error occurs:

```json
{
  "type": "error",
  "payload": {
    "message": "Invalid message format"
  }
}
```

## Messages

### Subscribe to Milestones

Subscribe to receive milestone notifications:

**Request:**

```json
{
  "type": "subscribe",
  "payload": {
    "milestones": true
  }
}
```

**Behavior:**

- Marks connection as subscribed
- Evaluates all user's habits
- Sends any pending milestones (not previously notified)
- Records delivery of each milestone

**Example Response:**

```json
{
  "type": "streak_milestone",
  "payload": {
    "habitId": 1,
    "habitName": "Morning Run",
    "milestone": 3,
    "currentStreak": 3
  }
}
```

### Unsubscribe from Milestones

Unsubscribe from milestone notifications:

**Request:**

```json
{
  "type": "unsubscribe"
}
```

**Behavior:**

- Marks connection as unsubscribed
- No further messages are sent

## Milestones

### Supported Thresholds

- **3 days**: First milestone, celebrates the user's initial commitment
- **7 days**: Weekly streak, shows consistency
- **30 days**: Monthly streak, significant achievement

### Milestone Delivery

- Each milestone is sent **once per habit per milestone level**
- Reconnection does NOT resend already-delivered milestones
- Delivery state is persisted in PostgreSQL

### Example Sequence

```
User creates habit "Morning Run"

Day 1: Check in ✓
Day 2: Check in ✓
Day 3: Check in ✓
  → 3-day milestone delivered
  → Recorded in database

User reconnects (new WebSocket session)
  → 3-day milestone NOT resent (already delivered)

Day 4: Check in ✓
Day 5: Check in ✓
Day 6: Check in ✓
Day 7: Check in ✓
  → 7-day milestone delivered
  → Recorded in database
```

## Authorization

### User Isolation

- Each WebSocket connection is bound to a specific user via JWT token
- User ID is extracted from token during authentication
- Users cannot receive notifications for other users' habits
- User ID is never accepted directly from client messages

### Token Validation

- JWT token must be valid and not expired
- Invalid tokens result in connection rejection (code 1008)
- Missing tokens result in connection rejection (code 1008)

## Error Handling

### Invalid Messages

Invalid messages result in error responses:

```json
{
  "type": "error",
  "payload": {
    "message": "Invalid message format"
  }
}
```

### Connection Errors

If connection establishment fails:

- Code `1008`: Invalid authentication token or missing token
- Code `1011`: Internal server error

### Message Errors

If message processing fails:

- Invalid JSON: Error message sent
- Missing type field: Error message sent
- Unknown message type: Error message sent
- Invalid payload: Error message sent

## Database Schema

Milestone delivery state is persisted in the `milestone_notifications` table:

```sql
CREATE TABLE milestone_notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  milestone INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, habit_id, milestone)
);
```

The `UNIQUE` constraint ensures each milestone is recorded only once per habit.

## Implementation Example

### JavaScript/TypeScript Client

```javascript
class MilestoneNotifier {
  constructor(token) {
    this.token = token;
    this.ws = null;
  }

  connect() {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(`ws://api.example.com/api/ws?token=${this.token}`);

      this.ws.onopen = () => {
        this.subscribe();
        resolve();
      };

      this.ws.onmessage = (event) => {
        const message = JSON.parse(event.data);
        if (message.type === 'streak_milestone') {
          this.handleMilestone(message.payload);
        }
      };

      this.ws.onerror = (error) => {
        reject(error);
      };
    });
  }

  subscribe() {
    this.ws.send(JSON.stringify({
      type: 'subscribe',
      payload: { milestones: true }
    }));
  }

  handleMilestone(payload) {
    console.log(`🎉 ${payload.habitName} reached ${payload.milestone}-day streak!`);
    // Show notification, update UI, etc.
  }

  close() {
    if (this.ws) {
      this.ws.close();
    }
  }
}

// Usage
const notifier = new MilestoneNotifier(accessToken);
await notifier.connect();
```

## Testing

Run WebSocket tests with:

```bash
npm test -- websocket.handler.test.ts --forceExit
```

Test coverage includes:

- ✅ Authenticated connection acceptance
- ✅ Unauthenticated connection rejection
- ✅ Subscribe message handling
- ✅ 3-day, 7-day, 30-day milestones
- ✅ No duplicate notifications after reconnect
- ✅ User isolation (can't receive other user's notifications)
- ✅ Invalid message rejection
- ✅ Error message format

## Performance Considerations

### Connection Pooling

- WebSocket connections are kept alive
- Server manages multiple concurrent connections per user
- Each connection is independent

### Milestone Calculation

- Milestones are calculated on-demand at subscription time
- Uses existing streak calculation service
- Checks delivery state in database
- Minimal database queries per subscription

## Future Enhancements

- Message history (retrieve past milestones)
- Custom milestone thresholds per user
- Achievement badges for milestones
- Social sharing of milestones
- Reminder notifications before milestones
