# iOS Authentication Setup Guide

## Overview

The Habit Tracker iOS app implements a complete, secure OAuth authentication system with SSO support for Google and GitHub. This guide explains how to set up and use the authentication system.

## Architecture

### Components

1. **AuthService** (`HT/Core/Authentication/AuthService.swift`)
   - Handles OAuth flow using system browser (Safari)
   - Manages authorization code exchange
   - Persists tokens securely in Keychain
   - Implements token refresh logic

2. **SessionManager** (`HT/Core/Session/SessionManager.swift`)
   - Manages token lifecycle
   - Schedules automatic token refresh
   - Publishes authentication state changes
   - Handles logout

3. **AuthCoordinator** (`HT/Features/Authentication/AuthCoordinator.swift`)
   - Manages app-level authentication state
   - Restores session on app launch
   - Validates session with backend
   - Coordinates authentication flow

4. **AuthViewModel** (`HT/Features/Authentication/AuthViewModel.swift`)
   - Presentation logic for authentication UI
   - Manages authentication state (unauthenticated, authenticating, authenticated, error)
   - Handles user interactions

5. **LoginView** (`HT/Features/Authentication/LoginView.swift`)
   - Modern SwiftUI authentication UI
   - "Continue with Google" and "Continue with GitHub" buttons
   - Loading, error, and disabled states
   - Accessibility support

### Authentication State Machine

```
unauthenticated → authenticating → authenticated
                        ↓
                      error
                        ↓
                  unauthenticated
```

## Keychain Security

### Token Storage

All authentication tokens are stored securely in the iOS Keychain:

- **Access Token**: 15-minute expiry, used for API requests
- **Refresh Token**: 7-day expiry, used to obtain new access tokens

### Keychain Service Identifier

```
com.habittracker.app
```

### Not Stored in UserDefaults

For security, tokens are **never** stored in UserDefaults. UserDefaults is used only for non-sensitive user preferences like timezone.

### Keychain Attributes

Each token is protected by:
- Device passcode/biometric authentication
- Automatic deletion on app uninstall
- Secure enclave protection

## Session Restoration Flow

### On App Launch

1. **App loads → HTApp initializes**
   - Creates AuthCoordinator and AppCoordinator
   - Sets up environment objects

2. **RootView shows splash screen**
   - Displays "Habit Tracker" with loading spinner
   - Sets `isRestoring = true`

3. **AuthCoordinator.restoreSession() called**
   - Reads access token and refresh token from Keychain
   - Reads user ID from UserDefaults
   - If tokens exist, calls `sessionManager.restoreSessionIfAvailable()`
   - SessionManager validates tokens are not nil

4. **Backend Validation (Optional)**
   - Could call `/auth/validate` endpoint to verify tokens with server
   - Currently trusts Keychain persistence (tokens are signed JWT)

5. **State Update**
   - If tokens valid: `isAuthenticated = true`, show MainTabView
   - If no tokens: `isAuthenticated = false`, show LoginView
   - Sets `isRestoring = false` to hide splash screen

### Code Flow

```swift
// On app launch
await authCoordinator.restoreSession()

// Inside restoreSession()
if let restored = try await sessionManager.restoreSessionIfAvailable() {
  // Backend validation (optional)
  try await validateSessionWithBackend()
  isAuthenticated = true
} else {
  isAuthenticated = false
}
isRestoring = false
```

## Authentication Flow

### 1. User Taps "Continue with Google/GitHub"

```swift
// LoginView
Button(action: { Task { await viewModel.signInWithGoogle() } })
```

### 2. AuthViewModel Updates State

```swift
viewModel.authState = .authenticating
```

### 3. ASWebAuthenticationSession Opens Safari

```swift
// AuthService
let session = ASWebAuthenticationSession(
  url: authUrl,
  callbackURLScheme: "habittracker"
) { callbackUrl, error in
  // Handle callback
}
session.start()
```

### 4. User Authenticates in Safari

- User logs in with Google/GitHub
- Provider redirects to `habittracker://oauth-callback?code=AUTH_CODE&state=...`
- Safari closes, returns to app

### 5. Authorization Code Captured

```swift
// Extract code from deep-link
let code = components.queryItems?.first(where: { $0.name == "code" })?.value
```

### 6. Code Exchanged for Tokens

```swift
// APIClient makes POST request to backend
POST /v1/auth/google/callback
{
  "code": "AUTH_CODE"
}
```

### 7. Backend Validates & Returns Tokens

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "user": {
      "id": 123,
      "email": "user@example.com",
      "displayName": "John Doe",
      "avatarUrl": "https://..."
    }
  }
}
```

### 8. Tokens Stored in Keychain

```swift
storageManager.saveAccessToken(data.accessToken)
storageManager.saveRefreshToken(data.refreshToken)
storageManager.saveUserID(data.user.id)
```

### 9. Session Active, App Shows MainTabView

```swift
authCoordinator.isAuthenticated = true
// RootView automatically shows MainTabView
```

## URL Scheme Registration

### Info.plist Configuration

Add custom URL scheme to `HT/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>habittracker</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.habittracker.oauth</string>
  </dict>
</array>
```

### OAuth Callback URL

Both OAuth providers must be configured with redirect URI:

```
habittracker://oauth-callback
```

## Automatic Token Refresh

### Refresh Schedule

- SessionManager schedules token refresh every 10 minutes
- Prevents token expiry (15-minute access token lifetime)
- Runs automatically in background

### Refresh Flow

```
Timer fires every 10 minutes
  ↓
Call sessionManager.performTokenRefresh()
  ↓
POST /v1/auth/refresh { refreshToken }
  ↓
Backend validates refresh token
  ↓
Return new access token
  ↓
Store in Keychain
```

### Failed Refresh

If token refresh fails (expired refresh token, network error):
- Session invalidated
- User logged out
- LoginView displayed

## Login UI Components

### LoginView

Modern SwiftUI authentication screen with:
- Header: "Habit Tracker" title and tagline
- Sign-in buttons for Google and GitHub
- Loading state with spinner during authentication
- Disabled state during authentication
- Error message display
- Accessibility labels and hints
- Responsive layout

### State Management

```swift
enum AuthenticationState {
  case unauthenticated
  case authenticating
  case authenticated
  case error(String)
}
```

### UI States

1. **Unauthenticated**: Buttons enabled, no loading indicator
2. **Authenticating**: Buttons disabled, loading spinner
3. **Authenticated**: View dismissed, MainTabView shown
4. **Error**: Error message displayed, user can dismiss and retry

## Testing

### Unit Tests

Located in `HTTests/AuthenticationTests.swift`:

- Session restoration with valid tokens
- Session restoration with no tokens
- Keychain token persistence
- Tokens NOT stored in UserDefaults
- Authentication state transitions
- Logout clears tokens
- User ID storage and retrieval

### Running Tests

```bash
# In Xcode
⌘U (or Product → Test)

# From command line
xcodebuild test -scheme HT
```

### Test Scenarios

```swift
testRestoreSession_NoTokensInKeychain_ReturnsUnauthenticated()
testRestoreSession_ValidTokenInKeychain_ReturnsAuthenticated()
testKeychainStorage_TokenPersistence()
testKeychainStorage_NoUserDefaults_ForTokens()
testLogout_ClearsTokens()
```

## Error Handling

### Authentication Errors

```swift
enum OAuthError: LocalizedError {
  case cancelled           // User cancelled in browser
  case authFailed(String)  // OAuth provider error
  case noAuthCode          // No code in redirect
  case tokenExchangeFailed // Backend token exchange failed
  case refreshFailed       // Token refresh failed
  case noRefreshToken      // Refresh token missing
  case invalidURL          // Invalid OAuth URL
}
```

### Error Display

- Errors shown in LoginView error banner
- User can dismiss and retry
- AuthViewModel provides localized error messages

## Security Best Practices

### ✅ Implemented

- Authorization code stored in memory only, not persisted
- Client secret exchanged server-to-server
- Tokens stored in Keychain with device protection
- JWT tokens signed with backend secret
- Audience claim prevents token misuse
- Automatic token refresh before expiry
- PKCE handled by ASWebAuthenticationSession
- State parameter validated for CSRF protection
- Tokens cleared on logout

### ⚠️ Future Enhancements

- Token binding to device fingerprint
- Certificate pinning for API communications
- Token blacklist on backend for logout
- Biometric re-authentication for sensitive operations
- Rate limiting on auth endpoints

## Troubleshooting

### Tokens Not Persisting

**Issue**: After app restart, user needs to re-authenticate

**Solutions**:
- Check Keychain service identifier: `com.habittracker.app`
- Verify StorageManager is using Keychain, not UserDefaults
- Check app has Keychain entitlement in Signing & Capabilities

### Authentication Hangs

**Issue**: App doesn't return from Safari OAuth screen

**Solutions**:
- Verify URL scheme registered in Info.plist: `habittracker`
- Check OAuth provider redirect URI: `habittracker://oauth-callback`
- Check network connectivity
- Verify OAuth credentials not expired

### Session Restoration Fails

**Issue**: App shows LoginView even after successful login

**Solutions**:
- Check tokens were saved to Keychain (not UserDefaults)
- Verify `authCoordinator.restoreSession()` called in HTApp
- Check JWT tokens not expired
- Verify backend token validation endpoint (if implemented)

### OAuth Provider Errors

**Issue**: "Invalid redirect URI" or authentication fails

**Solutions**:
- **Google**: Go to [Google Cloud Console](https://console.cloud.google.com/) → Credentials → OAuth client ID → Verify redirect URI
- **GitHub**: Go to [GitHub Developer Settings](https://github.com/settings/developers) → OAuth App → Verify callback URL
- Ensure redirect URI matches exactly: `habittracker://oauth-callback`

## Privacy & Compliance

### Data Stored

- **Keychain**: Access token, refresh token (sensitive)
- **UserDefaults**: User ID, timezone (non-sensitive)
- **In-Memory**: Authorization code (temporary)

### Data Cleared

On logout or app uninstall:
- Tokens automatically removed from Keychain
- User ID cleared from UserDefaults

### GDPR/CCPA Compliance

- Users can delete account (deletes all user data on backend)
- No persistent tracking or analytics
- Tokens stored only locally on device
- No third-party sharing (OAuth only authenticates, doesn't track)

## References

- [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [OAuth 2.0 for Mobile Apps](https://oauth.net/2/native-apps/)
- [PKCE Specification](https://tools.ietf.org/html/rfc7636)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
