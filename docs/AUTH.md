# Authentication Flow

## OAuth 2.0 with OIDC

Habit Tracker supports authentication via Google and GitHub.

### iOS Client Flow

1. User taps "Sign in with Google" or "Sign in with GitHub"
2. iOS opens system browser via `ASWebAuthenticationSession`
3. Browser redirects to backend auth endpoint

### Backend Authorization

1. Backend initiates OAuth with provider (Google/GitHub)
2. User authorizes on provider's consent screen
3. Provider redirects back to backend with authorization code
4. Backend exchanges code for tokens
5. Backend verifies ID token signature
6. Backend creates/updates user in database
7. Backend generates JWT tokens
8. Backend redirects to iOS app via custom scheme: `habittracker://auth/success?access_token=...&refresh_token=...`

### JWT Tokens

**Access Token** (15 minutes)
- Used for API requests
- Included in Authorization header: `Bearer <access_token>`
- Short-lived for security

**Refresh Token** (7 days)
- Used to obtain new access tokens
- Stored securely in iOS Keychain
- Implements rotation on use

### iOS Token Management

1. Tokens stored in Keychain (secure, encrypted)
2. On app launch, check if access token expired
3. If expired, POST to `/auth/refresh` with refresh token
4. Receive new tokens, update Keychain
5. On 401 response, refresh and retry request

### Refresh Token Rotation

- Backend issues new refresh token with each refresh
- Old token invalidated immediately
- Prevents token reuse attacks
- If old token used again: suspicious activity → invalidate all tokens → require re-login

## Endpoints

```
POST /auth/google/callback
Body: { code, state }
Response: { accessToken, refreshToken, user }

POST /auth/github/callback
Body: { code, state }
Response: { accessToken, refreshToken, user }

POST /auth/refresh
Body: { refreshToken }
Response: { accessToken, refreshToken }

POST /auth/logout
Body: { refreshToken }
Response: { success: true }
```

## Security Considerations

- PKCE (Proof Key for Code Exchange) on iOS
- CSRF protection via state parameter
- Token expiration enforced
- Tokens never sent to browser (no localStorage)
- Keychain encryption on iOS
- HTTPS only
- Secure cookie flags

## Implementation Status

Authentication structure is defined. OAuth exchange flow coming soon.
