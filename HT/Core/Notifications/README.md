# Notification System

The Notification System provides in-app toast/banner notifications for milestone achievements and other events. It integrates with the WebSocket service to display real-time notifications without requiring screen refreshes.

## Components

### ToastNotification

Data model for notifications.

```swift
struct ToastNotification: Identifiable, Equatable {
  let id: UUID
  let title: String
  let message: String
  let type: NotificationType
  let duration: TimeInterval
}
```

**Notification Types:**

- **milestone(days: Int)** - Milestone achievement
  - 3 days: 🔥 "3-day streak!"
  - 7 days: ⭐ "7-day streak!"
  - 30 days: 🏆 "30-day streak!"
- **success** - Successful operation
- **error** - Error occurred
- **info** - General information

**Creation:**

```swift
// From MilestoneNotification
let milestone = MilestoneNotification(...)
let toast = ToastNotification.milestone(milestone)

// Custom
let toast = ToastNotification(
  title: "Success",
  message: "Operation completed",
  type: .success,
  duration: 3.0
)
```

### NotificationStore

Observable store managing notification state and auto-dismiss.

```swift
@MainActor
class NotificationStore: ObservableObject {
  @Published var currentNotification: ToastNotification?

  func show(_ notification: ToastNotification)
  func dismiss(_ id: UUID)
  func dismissAll()
}
```

**Features:**

- Tracks one active notification at a time
- Automatic dismiss after duration expires
- Manual dismiss via UI button
- Cancels previous dismiss timers on new notification

**Usage:**

```swift
@StateObject private var store = NotificationStore()

// Show notification
let toast = ToastNotification(...)
store.show(toast)

// Auto-dismisses after duration
// Or manually dismiss
store.dismiss(toast.id)
```

### ToastView

SwiftUI component displaying toast notifications.

**Features:**

- Slides in from top with opacity transition
- Icon, title, and message
- Close button for manual dismiss
- Progress bar showing remaining time
- Shadows and rounded corners
- Responsive layout

**Usage:**

```swift
ToastView(notification: notification)
  .environmentObject(notificationStore)
```

### ToastContainerView

Container managing the toast display and positioning.

Places notifications at the top of the screen without blocking content.

**Usage:**

Add to the app root:

```swift
ZStack {
  MainContent()
  
  ToastContainerView()
}
```

### MilestoneNotificationManager

Coordinates between WebSocket events and NotificationStore.

```swift
@MainActor
class MilestoneNotificationManager: ObservableObject {
  func start()
  func stop()
}
```

**Features:**

- Connects to WebSocket
- Listens for milestone events
- Creates ToastNotifications from milestones
- Handles connection errors and reconnection
- Automatic cleanup on stop

**Usage:**

```swift
@StateObject private var manager = MilestoneNotificationManager()

VStack {
  // Content
}
.onAppear {
  manager.start()
}
.onDisappear {
  manager.stop()
}
```

## Notification Examples

### 3-Day Milestone

```
🔥 3-day streak!
You completed "Morning Run" for 3 consecutive days.
```

### 7-Day Milestone

```
⭐ 7-day streak!
You completed "Exercise" for 7 consecutive days.
```

### 30-Day Milestone

```
🏆 30-day streak!
You completed "Reading" for 30 consecutive days.
```

## Integration

### App Setup

```swift
@main
struct HTApp: App {
  @StateObject private var notificationManager = MilestoneNotificationManager()

  var body: some Scene {
    WindowGroup {
      ZStack {
        MainTabView()
        
        ToastContainerView()
      }
      .onAppear {
        notificationManager.start()
      }
      .onDisappear {
        notificationManager.stop()
      }
    }
  }
}
```

### Manual Notifications

```swift
@EnvironmentObject var notificationStore: NotificationStore

Button(action: {
  let toast = ToastNotification(
    title: "Success",
    message: "Habit updated",
    type: .success
  )
  notificationStore.show(toast)
}) {
  Text("Show Success")
}
```

## Behavior

### Appearance

- Slides in from top with smooth animation
- Displays title and message
- Shows close button
- Progress bar indicates remaining time

### Duration

- 3-day milestone: 5 seconds
- 7-day milestone: 5 seconds
- 30-day milestone: 5 seconds
- Error: 3 seconds
- Custom: configurable

### Dismissal

- Auto-dismisses after duration
- Manual dismiss via close button
- Only one notification shown at a time
- Replaces previous notification if shown while one is active

### User Interaction

- Close button dismisses immediately
- Tapping the toast area does nothing
- Notifications do not block user interaction with app

## Testing

Tests cover:

- Initial state
- Show notification
- Replace notification
- Dismiss notification
- Auto-dismiss timing
- Milestone notification types (3, 7, 30 days)
- Background colors
- Notification equality
- Custom notification creation

Run tests:

```bash
xcodebuild test -scheme HT -testPlan HTTests
```

## Architecture Decision: In-App Only

This system uses WebSocket notifications instead of system push notifications because:

1. **Real-Time**: WebSocket provides instant delivery without OS delays
2. **User Context**: Notifications appear in-app without breaking user flow
3. **Simpler**: No server configuration or push certificate management
4. **Privacy**: No sending data to Apple's push service
5. **Testing**: Easier to test in simulator without APNs
6. **Control**: App has full control over notification styling and behavior

## Future Enhancements

- Notification history/log
- Swipe-to-dismiss gesture
- Notification sounds
- Haptic feedback
- Multiple notification queue (show multiple at once)
- Persistent notifications (don't auto-dismiss)
- Notification actions/buttons
