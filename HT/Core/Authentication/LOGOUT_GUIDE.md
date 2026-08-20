# Logout Implementation Guide

## Overview

The logout system completely clears user authentication and private data from the app, ensuring no data remains accessible after logout.

## Logout Flow

1. **User taps logout** → Confirmation dialog shown
2. **Backend invalidation** → POST /auth/logout called
3. **WebSocket disconnect** → Real-time connections severed
4. **Keychain clear** → Access/refresh tokens removed
5. **Application state** → Cache and user data cleared
6. **Navigation** → Return to LoginView

## Components

### LogoutService

Coordinates all logout operations:

```swift
let service = LogoutService()
try await service.logout()
```

**Operations:**
1. Invalidates backend session
2. Disconnects WebSocket
3. Clears Keychain data
4. Clears application cache
5. Clears user data

### StorageManager Extensions

Keychain management methods:

```swift
// Tokens
manager.getAccessToken() -> String?
manager.saveAccessToken(_ token: String)
manager.clearAccessToken()

manager.getRefreshToken() -> String?
manager.saveRefreshToken(_ token: String)
manager.clearRefreshToken()

// User data
manager.getUserId() -> Int?
manager.saveUserId(_ id: Int)
manager.clearUser()
```

### SettingsView

User-facing logout UI:

```swift
struct SettingsView: View {
  @StateObject private var logoutService = LogoutService()
  @State private var showLogoutConfirmation = false

  // Shows logout button with confirmation dialog
}
```

## Security Guarantees

### Data Clearance

✅ **Access tokens** - Removed from Keychain
✅ **Refresh tokens** - Removed from Keychain
✅ **User ID/Email** - Removed from UserDefaults
✅ **HTTP cache** - Cleared from URLCache
✅ **WebSocket** - Forcefully disconnected
✅ **Backend session** - Invalidated on server

### No Data Leaks

- No cached API responses remain
- No user-specific data in memory
- No active WebSocket connections
- Next login loads fresh data only
- Browser/cache history not accessible

## Error Handling

### Backend Logout Failure

If the backend logout fails:

```swift
// Local cleanup continues
// Backend invalidation attempted but not required
// User can still proceed to login
```

### Network Errors

Logout continues despite network issues:

```swift
// WebSocket disconnected locally
// Keychain cleared regardless
// App returns to LoginView
```

## State Management

### Before Logout

- ✅ Access token in Keychain
- ✅ User data in memory
- ✅ WebSocket connection active
- ✅ Cache populated

### After Logout

- ❌ No tokens in storage
- ❌ No user data in memory
- ❌ WebSocket disconnected
- ❌ Cache cleared

## Testing

Comprehensive test coverage:

```swift
// Backend invalidation
testLogoutCallsBackendLogout()
testLogoutContinuesOnBackendError()

// WebSocket
testLogoutDisconnectsWebSocket()

// Keychain
testLogoutClearsAccessToken()
testLogoutClearsRefreshToken()
testLogoutClearsUser()

// Cache
testLogoutClearsApplicationCache()

// Complete sequence
testCompleteLogoutSequence()
testNoDataRemainsAfterLogout()
testWebSocketDisconnectedAfterLogout()
```

## Implementation Details

### LogoutService Flow

```
logout()
  ├─ invalidateBackendSession()
  │   └─ POST /auth/logout (best-effort)
  ├─ webSocketService.disconnect()
  ├─ clearAuthenticationData()
  │   ├─ clearAccessToken()
  │   ├─ clearRefreshToken()
  │   └─ clearUser()
  └─ clearApplicationState()
      └─ URLCache.shared.removeAllCachedResponses()
```

### Error Handling Strategy

**Fail-safe**: Each step is independent. If any step fails:

1. Backend logout fails → Continue with local cleanup
2. WebSocket disconnect fails → Continue with Keychain
3. Cache clear fails → Still return to LoginView

This ensures user can always logout and login with fresh session.

## Next Login

After logout:

1. User returns to LoginView
2. New authentication flow starts
3. Only authenticated user's data loads
4. Fresh WebSocket session established
5. New tokens stored in Keychain

## Security Considerations

### Token Expiry

- Tokens cleared immediately on logout
- Backend session invalidated for extra safety
- Even if tokens somehow remain, they're invalid server-side

### Session Isolation

- Each login gets fresh session
- Previous user's data never visible
- Cache cleared between sessions
- WebSocket cleaned up completely

### Concurrent Access

- Logout is atomic per user
- No race conditions with background tasks
- WebSocket fully disconnected before logout completes

## Troubleshooting

### Data Still Visible After Logout

- Clear app cache manually
- Verify Keychain was actually cleared
- Check WebSocket truly disconnected
- Look for retained references in memory

### Can't Login After Logout

- Verify tokens were cleared
- Check backend session was invalidated
- Ensure no cached responses interfere
- Try force-kill and relaunch app

### WebSocket Reconnects After Logout

- Verify WebSocket.disconnect() called
- Check for automatic reconnection logic
- Ensure logout completes before navigation
- Look for dangling event listeners

## Best Practices

1. **Always confirm logout** - Show dialog before logout
2. **Handle errors gracefully** - Don't block logout on errors
3. **Clear all data** - No exceptions for any data type
4. **Validate next login** - Ensure fresh session established
5. **Test extensively** - Verify no data leaks

## Future Enhancements

- Device token invalidation
- Active session revocation
- Logout from all devices
- Audit log of logout events
- Logout timeout

