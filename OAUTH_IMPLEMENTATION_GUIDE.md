# OAuth SSO Implementation Guide

## Architecture Overview

This application implements a secure OAuth 2.0 authentication system using industry-standard patterns for native iOS applications.

### Authentication Flow

#### iOS Client Flow
1. User taps "Sign in with Google/GitHub"
2. `AuthService` opens `ASWebAuthenticationSession` (system Safari)
3. User authorizes in browser
4. Browser redirects to deep-link `habittracker://oauth-callback?code=...`
5. `AuthService` captures authorization code
6. iOS app exchanges code for JWT tokens via backend
7. Tokens stored in iOS Keychain
8. `SessionManager` maintains session and handles token refresh
9. Authenticated API requests include `Authorization: Bearer <token>` header

#### Backend Flow
1. Receive authorization code from iOS client at `POST /v1/auth/google/callback`
2. Backend exchanges code for OAuth provider's access token (server-to-server, secret protected)
3. Fetch user profile from OAuth provider using access token
4. Lookup or create user in database using (provider, provider_user_id) tuple
5. Generate app's JWT tokens (access: 15min, refresh: 7 days)
6. Return tokens and user data to iOS client

#### Token Refresh
1. APIClient detects 401 response
2. AuthService refreshes token via `POST /v1/auth/refresh`
3. New access token generated and saved to Keychain
4. Original request automatically retried with new token

#### Session Restoration
1. App starts
2. `SessionManager.initializeSession()` runs
3. Check for valid tokens in Keychain
4. If found, user is authenticated
5. Schedule periodic token refresh (every 10 minutes)

## Backend Implementation

### OAuth Services (`src/services/oauth.ts`)

Implements provider-agnostic interface:

```typescript
interface OAuthProvider {
  exchangeCodeForTokens(code: string): Promise<string>
  fetchUserInfo(accessToken: string): Promise<OAuthUserInfo>
}

// Implementations:
- GoogleOAuthService
- GitHubOAuthService
- MockOAuthService (for testing)
```

**Key Methods:**
- `exchangeCodeForTokens(code)` — Server-to-server code exchange with provider
- `fetchUserInfo(accessToken)` — Fetch user profile from provider

**Mock Implementation:**
- Used in test environment
- No real HTTP calls to OAuth providers
- Controlled responses for testing

### User Repository (`src/repositories/userRepository.ts`)

Manages user creation and lookup:

```typescript
// Find or create user by (provider, provider_user_id)
async function findOrCreateUser(data: CreateUserData): Promise<User>

// Additional functions:
- getUserById(userId)
- getUserByEmail(email)
```

**Database Schema:**
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  provider VARCHAR(50) NOT NULL,
  provider_user_id VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  display_name VARCHAR(255),
  avatar_url TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE(provider, provider_user_id)
)
```

### Authentication Routes (`src/routes/auth.ts`)

Four endpoints:

#### 1. POST /v1/auth/google/callback
Exchange Google authorization code for JWT tokens.

**Request:**
```json
{
  "code": "authorization_code_from_browser"
}
```

**Response:**
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
  },
  "timestamp": "2026-08-20T..."
}
```

#### 2. POST /v1/auth/github/callback
Exchange GitHub authorization code for JWT tokens.

Same request/response format as Google.

#### 3. POST /v1/auth/refresh
Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "refresh_token_from_keychain"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "accessToken": "new_eyJ..."
  },
  "timestamp": "2026-08-20T..."
}
```

#### 4. POST /v1/auth/logout
Invalidate user session (best-effort).

**Response:**
```json
{
  "success": true,
  "timestamp": "2026-08-20T..."
}
```

### Authentication Middleware (`src/middleware/authMiddleware.ts`)

**`authenticateToken(req, res, next)`**
- Extracts JWT from `Authorization: Bearer <token>` header
- Verifies token signature
- Attaches `req.user` with JWT payload
- Returns 401 if missing or invalid

**`optionalAuthenticate(req, res, next)`**
- Same as above but doesn't fail if token missing
- Used for endpoints that work with or without auth

### JWT Configuration (`src/utils/tokenUtils.ts`)

**Token Claims:**
```typescript
interface JWTPayload {
  sub: number                        // User ID
  email: string
  oauthProvider: 'google' | 'github'
  oauthId: string                    // Provider's user ID
  iat: number                        // Issued at
  exp: number                        // Expiration
  aud: 'ios-app'                     // Audience
}
```

**Expiry:**
- Access token: 15 minutes (short-lived)
- Refresh token: 7 days (long-lived)

## iOS Implementation

### AuthService (`Core/Authentication/AuthService.swift`)

Handles OAuth flow and token management:

```swift
// OAuth flows
func signInWithGoogle() async throws -> AuthenticationResponse
func signInWithGitHub() async throws -> AuthenticationResponse

// Token management
func logout() async throws
func refreshTokenIfNeeded() async throws

// Session restoration
func restoreSessionIfAvailable() async throws -> AuthenticationResponse?
```

**Key Implementation Details:**
- Uses `ASWebAuthenticationSession` for browser-based auth
- Implements `ASWebAuthenticationPresentationContextProviding`
- Handles PKCE automatically (via ASWebAuthenticationSession)
- State parameter validated by system
- Authorization code captured via deep-link

### SessionManager (`Core/Session/SessionManager.swift`)

Manages session lifecycle and token refresh:

```swift
@MainActor
class SessionManager: ObservableObject {
  @Published var isAuthenticated = false
  @Published var currentUser: AuthenticationResponse.User?
  
  func initializeSession() async
  func signInWithGoogle() async
  func signInWithGitHub() async
  func logout() async
  
  private func scheduleTokenRefresh()
  private func performTokenRefresh() async
}
```

**Features:**
- Auto-refresh tokens every 10 minutes
- Continues auto-logout if refresh fails
- @MainActor ensures thread-safe updates
- ObservableObject for SwiftUI integration

### StorageManager (`Core/Storage/StorageManager.swift`)

Secure token storage in iOS Keychain:

```swift
var accessToken: String? { get }
var refreshToken: String? { get }

func saveAccessToken(_ token: String)
func saveRefreshToken(_ token: String)
func clearAllTokens()
```

**Security:**
- Uses `SecItemAdd`, `SecItemCopyMatching`, `SecItemDelete`
- Service: `com.habittracker.app`
- Account: `accessToken`, `refreshToken`
- Type: Generic Password

### APIClient (`Core/Networking/APIClient.swift`)

HTTP client with automatic token refresh:

```swift
func request<T: Decodable>(endpoint: String, method: HTTPMethod, body: Encodable?) async throws -> T

// Automatic 401 handling:
// 1. Detects 401 response
// 2. Calls authService.refreshTokenIfNeeded()
// 3. Retries request with new token
```

**Authorization Header:**
- Format: `Authorization: Bearer <access_token>`
- Attached automatically if token exists in Keychain

### AuthViewModel (`Features/Authentication/AuthViewModel.swift`)

View model for login screen:

```swift
@MainActor
class AuthViewModel: ObservableObject {
  @Published var authState: AuthenticationState
  @Published var errorMessage: String?
  
  func signInWithGoogle() async
  func signInWithGitHub() async
  func clearError()
  
  var isSignInEnabled: Bool
}
```

**Features:**
- 120-second timeout on auth operations
- Error state management
- UI state derived from authentication state
- Integration with SessionManager

### LoginView (`Features/Authentication/LoginView.swift`)

User-facing authentication UI:

```swift
struct LoginView: View {
  @StateObject private var viewModel = AuthViewModel()
  
  // Shows:
  // - Header with app title
  // - Google sign-in button
  // - GitHub sign-in button
  // - Error display and dismissal
  // - Loading states
  // - Accessibility labels
}
```

**Features:**
- Modern light-mode-only design
- Loading indicators during auth
- Error messages with dismiss
- Accessibility hints for sign-in buttons
- Touch-optimized buttons

### Deep-Link Configuration

**Info.plist:**
```xml
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>habittracker</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.habittracker.app</string>
  </dict>
</array>
```

**Callback URL Format:**
```
habittracker://oauth-callback?code=...&state=...
```

## Security Considerations

### Authorization Code
- Single-use, short-lived (typically 10 minutes)
- Exchanged server-to-server with OAuth provider
- Never stored in app

### Client Secret
- Stored on backend only
- Never transmitted to or stored on iOS
- Used only in server-to-server communication

### Access Token
- 15-minute expiry (short-lived)
- Stored in iOS Keychain
- Included in every API request
- Automatically refreshed before expiry

### Refresh Token
- 7-day expiry (long-lived)
- Stored in iOS Keychain
- Used only to obtain new access tokens
- Should be revoked on logout

### PKCE (Proof Key for Code Exchange)
- Automatically handled by `ASWebAuthenticationSession`
- Prevents code interception attacks
- No implementation required in app

### State Parameter
- Automatically generated and validated by `ASWebAuthenticationSession`
- Validates redirect integrity
- Prevents CSRF attacks

### Keychain Security
- OS-managed encryption
- Per-device encryption
- Requires biometric or passcode for access
- Data wiped on app uninstall

### Token Binding (Future)
- Bind tokens to device fingerprint
- Prevent token theft if Keychain accessed externally
- Requires backend support

## Testing

### Backend Tests (`tests/integration/auth.routes.test.ts`)

```typescript
describe('Authentication Routes', () => {
  // Google OAuth
  test('POST /v1/auth/google/callback authenticates user')
  test('POST /v1/auth/google/callback creates new user')
  test('POST /v1/auth/google/callback reuses existing user')
  
  // GitHub OAuth
  test('POST /v1/auth/github/callback authenticates user')
  test('POST /v1/auth/github/callback reuses existing user')
  
  // Token Refresh
  test('POST /v1/auth/refresh returns new access token')
  test('POST /v1/auth/refresh fails with invalid refresh token')
  
  // Logout
  test('POST /v1/auth/logout succeeds')
  
  // Error Handling
  test('POST /v1/auth/google/callback returns 400 if code missing')
  test('POST /v1/auth/google/callback returns error on OAuth failure')
})
```

**Test Environment:**
- Uses `MockOAuthService` instead of real providers
- No real HTTP calls to Google/GitHub
- In-memory controlled responses
- Fast and reliable

### iOS Tests (`HTTests/AuthenticationTests.swift`)

```swift
class AuthenticationTests: XCTestCase {
  // Session Restoration
  func testRestoreSession_NoTokens_ReturnsUnauthenticated()
  func testRestoreSession_ValidToken_ReturnsAuthenticated()
  
  // Token Lifecycle
  func testAccessToken_SavedToKeychain()
  func testRefreshToken_SavedToKeychain()
  func testTokens_ClearedOnLogout()
  
  // Error Handling
  func testAuthFailed_ErrorDisplayed()
  func testCancelledAuth_ErrorCleared()
}
```

## Configuration

### Environment Variables (Backend)

```bash
# OAuth Credentials
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...

# Redirect URIs
GOOGLE_REDIRECT_URI=http://localhost:3000/v1/auth/google/callback
GITHUB_REDIRECT_URI=http://localhost:3000/v1/auth/github/callback

# JWT Signing
JWT_SECRET=your-secret-key-here
JWT_ACCESS_TOKEN_EXPIRY=15m
JWT_REFRESH_TOKEN_EXPIRY=7d
```

### Info.plist (iOS)

Already configured with deep-link scheme:
```xml
<key>URL Schemes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>habittracker</string>
    </array>
  </dict>
</array>
```

## Troubleshooting

### OAuth Flow Hangs
- Check network connectivity
- Verify OAuth provider credentials are correct
- Check deep-link URL scheme in Info.plist
- Verify backend `/v1/auth/google/callback` and `/v1/auth/github/callback` endpoints are accessible

### "No authorization code received" Error
- User may have cancelled auth flow
- Check if deep-link is properly configured
- Verify OAuth app settings allow the redirect URI

### "Token exchange failed" Error
- Backend may not have reached OAuth provider
- Verify backend credentials (client ID, client secret)
- Check backend logs for detailed error

### Tokens Lost After App Restart
- Keychain may be locked
- Device biometric/passcode required
- Verify Keychain operations succeed

### Automatic Token Refresh Not Working
- Check that refresh token exists in Keychain
- Verify 401 handling in APIClient
- Check backend `/v1/auth/refresh` endpoint

### User Stays Authenticated After Logout
- Verify Keychain is cleared in StorageManager
- Check LogoutService completes all cleanup steps
- Verify APIClient removes Authorization header

## Next Steps

### Phase 1: Verification (Current)
- Ensure OAuth routes are fully implemented ✓
- Verify tokens are properly signed and validated ✓
- Test OAuth flows end-to-end
- Verify deep-link handling

### Phase 2: Enhancements
- Implement token blacklist on logout (optional)
- Add device fingerprint for token binding
- Implement re-authentication for sensitive operations
- Add OAuth scope validation
- Add audit logging for authentication events

### Phase 3: Production
- Configure OAuth apps on Google/GitHub with production redirect URIs
- Generate production JWT signing key
- Set up HTTPS for all endpoints
- Configure CORS for production domain
- Set up monitoring and alerting for auth failures
- Implement rate limiting on auth endpoints
- Add MFA support (optional)

## References

- [OAuth 2.0 Authorization Code Flow](https://tools.ietf.org/html/rfc6749#section-1.3.1)
- [PKCE for OAuth Mobile Apps](https://tools.ietf.org/html/rfc7636)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8949)
- [ASWebAuthenticationSession Documentation](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
- [iOS Keychain Documentation](https://developer.apple.com/documentation/security/keychain)

## Verification Checklist

- [ ] Backend OAuth services implemented for Google and GitHub
- [ ] User repository finds/creates users by (provider, provider_user_id)
- [ ] Authentication routes return JWT tokens with correct claims
- [ ] iOS AuthService opens browser for OAuth
- [ ] Deep-link URL scheme configured in Info.plist
- [ ] Authorization code captured and exchanged for tokens
- [ ] Tokens stored securely in iOS Keychain
- [ ] APIClient attaches Authorization header automatically
- [ ] 401 responses trigger automatic token refresh
- [ ] Refresh endpoint returns new access token
- [ ] SessionManager handles token lifecycle
- [ ] Session restored on app startup
- [ ] Auto-refresh scheduled every 10 minutes
- [ ] Logout clears tokens and session
- [ ] All backend tests pass
- [ ] All iOS tests pass
- [ ] No real OAuth secrets in code or repositories
- [ ] Environment variables documented
- [ ] Error handling covers all edge cases
- [ ] Accessibility features implemented

