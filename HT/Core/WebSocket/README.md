# WebSocket Service

The WebSocket Service provides real-time milestone notifications for habits. It handles connection management, authentication, message parsing, and automatic reconnection.

## Components

### WebSocketService

Main service for managing WebSocket connections and events.

**Features:**
- Authenticated connection using JWT token
- Automatic reconnection with exponential backoff
- Message encoding/decoding
- AsyncStream for reactive event handling
- Graceful disconnect on logout

**Usage:**

```swift
let wsService = WebSocketService()

// Listen for events
Task {
  for await event in wsService.eventStream() {
    switch event {
    case .connected:
      print("Connected")
    case .milestone(let notification):
      print("Milestone: \(notification)")
    case .error(let message):
      print("Error: \(message)")
    default:
      break
    }
  }
}

// Connect
await wsService.connect()

// Disconnect
await wsService.disconnect()
```

### WebSocketMessage

Encoding and decoding of client and server messages.

**Client Messages:**
- `subscribe()` - Subscribe to milestone notifications
- `unsubscribe()` - Unsubscribe from notifications

**Server Messages:**
- `streak_milestone` - Milestone notification
- `error` - Error message

### WebSocketEvent

Reactive events emitted by the WebSocket service.

**Event Types:**
- `connected` - Connection established
- `disconnected` - Connection closed
- `subscribed` - Subscription confirmed
- `milestone(MilestoneNotification)` - Milestone reached
- `error(String)` - Error occurred
- `reconnecting(attempt: Int)` - Reconnection attempt

### MilestoneNotification

Data model for milestone notifications.

```swift
struct MilestoneNotification: Decodable, Equatable {
  let habitId: Int
  let habitName: String
  let milestone: Int
  let currentStreak: Int
}
```

## Connection Lifecycle

1. **Create Service**: `let ws = WebSocketService()`
2. **Connect**: `await ws.connect()` - Extracts token from storage, establishes connection
3. **Listen**: `for await event in ws.eventStream()` - Receive events
4. **Disconnect**: `await ws.disconnect()` - Close connection, cleanup resources

## Authentication

The WebSocket connection is authenticated using the JWT token stored in Keychain:

1. Token is retrieved from StorageManager
2. Token is passed as query parameter: `?token=<JWT>`
3. Server verifies token and authenticates user
4. User ID is extracted from token (never from client)

## Reconnection Strategy

- **Max Attempts**: 5 reconnection attempts
- **Delay**: 3 seconds between attempts
- **Strategy**: Automatic reconnection on connection loss
- **Cleanup**: Exponential backoff with maximum attempts

## Error Handling

All errors are emitted as `.error(message)` events:

```swift
case .error(let message):
  print("WebSocket error: \(message)")
```

Common errors:
- `Missing authentication token` - No token in storage
- `Connection failed: ...` - Network error
- `Failed to parse message` - Invalid JSON from server
- `Max reconnection attempts reached` - Connection unstable

## Usage Example

See `MilestoneNotificationView.swift` for a complete example of:
- Connecting on view appearance
- Listening for milestone events
- Showing notifications
- Disconnecting on view disappearance

## Testing

Tests cover:
- Connection state management
- Subscribe/unsubscribe message format
- Message decoding (milestone, error)
- Invalid message handling
- Event stream exposition
- Disconnect behavior
- Missing token scenarios
- Event equality and hashing

Run tests:
```bash
xcodebuild test -scheme HT -testPlan HTTests
```
