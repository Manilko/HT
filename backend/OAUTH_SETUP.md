# OAuth Setup Guide

This document describes how to configure Google and GitHub OAuth for the Habit Tracker application.

## Backend Setup

### Environment Variables

All OAuth configuration is managed through environment variables in `.env`. See `.env.example` for the template.

**Required variables:**

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://localhost:3000/v1/auth/google/callback

# GitHub OAuth
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
GITHUB_REDIRECT_URI=http://localhost:3000/v1/auth/github/callback
```

### Setting Up Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable the Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth client ID"
5. Choose "Web application"
6. Add authorized redirect URIs:
   - `http://localhost:3000/v1/auth/google/callback` (development)
   - `https://api.habittracker.example/v1/auth/google/callback` (production)
7. Copy the Client ID and Client Secret to your `.env` file

### Setting Up GitHub OAuth

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Click "New OAuth App"
3. Fill in the application details:
   - Application name: "Habit Tracker"
   - Homepage URL: `http://localhost:3000` (development) or `https://habittracker.example` (production)
   - Authorization callback URL: `http://localhost:3000/v1/auth/github/callback` (development)
4. Copy the Client ID and Client Secret to your `.env` file

## iOS Setup

### URL Scheme Registration

The iOS app uses a custom URL scheme `habittracker://` to handle OAuth callbacks.

1. In Xcode, select the HT project
2. Select the HT app target
3. Go to the "Info" tab
4. Add a new URL scheme:
   - URL Schemes: `habittracker`
   - Identifier: `com.habittracker.oauth`

This enables the operating system to route OAuth callbacks back to the app via deep-links like:
```
habittracker://oauth-callback?code=auth_code&state=state_param
```

### Configure Client IDs

In `HT/Core/Authentication/AuthService.swift`, update the `getClientId(for:)` method with your OAuth provider credentials:

```swift
private func getClientId(for provider: String) -> String {
  switch provider {
  case "google":
    return "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
  case "github":
    return "YOUR_GITHUB_CLIENT_ID"
  default:
    return ""
  }
}
```

Alternatively, store client IDs in `Info.plist`:

```xml
<dict>
  <key>GOOGLE_CLIENT_ID</key>
  <string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
  <key>GITHUB_CLIENT_ID</key>
  <string>YOUR_CLIENT_ID</string>
</dict>
```

## OAuth Flow Overview

### 1. iOS App Initiates OAuth

User taps "Sign in with Google" or "Sign in with GitHub" button.

### 2. System Browser Opens

`ASWebAuthenticationSession` opens the provider's authorization endpoint in Safari:
- Google: `https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=habittracker://oauth-callback&...`
- GitHub: `https://github.com/login/oauth/authorize?client_id=...&redirect_uri=habittracker://oauth-callback&...`

### 3. User Authorizes

User logs in and grants permission to the app.

### 4. Provider Redirects to App

Provider redirects to `habittracker://oauth-callback?code=AUTH_CODE&state=STATE`.

### 5. iOS App Captures Authorization Code

`ASWebAuthenticationSession` captures the redirect and extracts the authorization code.

### 6. App Exchanges Code for Tokens

iOS app sends authorization code to backend:

```
POST /v1/auth/google/callback
Content-Type: application/json

{
  "code": "AUTH_CODE"
}
```

### 7. Backend Exchanges Code for Provider Tokens

Backend makes a server-to-server request to the provider:

```
POST https://oauth2.googleapis.com/token
Content-Type: application/x-www-form-urlencoded

code=AUTH_CODE&client_id=GOOGLE_CLIENT_ID&client_secret=GOOGLE_CLIENT_SECRET&grant_type=authorization_code&redirect_uri=http://localhost:3000/v1/auth/google/callback
```

Provider returns an access token.

### 8. Backend Fetches User Info

Backend uses the access token to fetch user profile:

```
GET https://www.googleapis.com/oauth2/v2/userinfo
Authorization: Bearer ACCESS_TOKEN
```

### 9. Backend Creates or Finds User

Backend looks up user by `(provider, provider_user_id)` tuple:
- If exists: returns existing user
- If not: creates new user with profile data

### 10. Backend Generates App Tokens

Backend generates JWT tokens for the iOS app:

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "refreshToken": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "user": {
      "id": 123,
      "email": "user@example.com",
      "displayName": "John Doe",
      "avatarUrl": "https://lh3.googleusercontent.com/..."
    }
  }
}
```

### 11. iOS App Stores Tokens

iOS app stores tokens in Keychain:
- Access Token: Used for API requests (15-minute expiry)
- Refresh Token: Used to get new access token (7-day expiry)

## Token Refresh

Access tokens expire after 15 minutes. The iOS app automatically refreshes tokens before expiry:

```
POST /v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "REFRESH_TOKEN"
}
```

Backend validates the refresh token and returns a new access token.

## Security Considerations

### Authorization Code
- Single-use, short-lived (10 minutes)
- Exchanged server-to-server (never exposed to iOS client)
- Contains state parameter to prevent CSRF attacks

### Client Secret
- Stored on backend only
- Never sent to iOS client
- Required to exchange authorization code for tokens

### PKCE (Proof Key for Code Exchange)
- Automatically handled by `ASWebAuthenticationSession`
- Adds additional layer of security for native apps

### JWT Tokens
- Signed with backend secret
- Include audience claim to prevent token misuse
- Access tokens expire in 15 minutes
- Refresh tokens expire in 7 days

### Keychain Storage
- Tokens stored in iOS Keychain (secure enclave)
- Protected by device passcode/biometric
- Automatically cleared on app uninstall

## Testing

### Development Environment

The backend can use mock OAuth providers for testing:

```bash
NODE_ENV=test npm test
```

Mock providers return test user data without making real HTTP requests to Google/GitHub.

### Manual Testing

1. Start backend:
   ```bash
   npm run dev
   ```

2. Run iOS simulator:
   ```bash
   xcode-build-and-run
   ```

3. Tap "Sign in with Google" or "Sign in with GitHub"

4. Authorize in browser

5. Verify app receives tokens and stores them

## Troubleshooting

### "Invalid OAuth configuration"

**Issue:** Backend throws error about missing OAuth credentials.

**Solution:** Ensure `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GITHUB_CLIENT_ID`, and `GITHUB_CLIENT_SECRET` are set in `.env`.

### "Authorization failed"

**Issue:** OAuth provider returns error during authorization.

**Solution:**
- Verify redirect URIs match exactly in provider settings
- Check that custom URL scheme is registered in iOS Info.plist
- Ensure OAuth credentials are not expired or revoked

### "Redirect URI mismatch"

**Issue:** Provider rejects redirect because URI doesn't match settings.

**Solution:**
- Google Console: Go to "Credentials" → "OAuth 2.0 Client IDs" and verify redirect URI
- GitHub: Go to "Developer Settings" → "OAuth Apps" and verify "Authorization callback URL"
- Both must match exactly: `http://localhost:3000/v1/auth/google/callback`

### Token stored but app doesn't show as authenticated

**Issue:** Tokens are in Keychain but app isn't using them.

**Solution:**
- Verify `APIClient` is adding Bearer token to Authorization header
- Check that `SessionManager.initializeSession()` is called on app launch
- Verify JWT tokens are not expired

## Production Deployment

### Certificate Generation

Generate strong JWT secret for production:

```bash
openssl rand -base64 32
```

Set in production `.env`:

```bash
JWT_SECRET=your-generated-secret-here
```

### OAuth Provider Configuration

Update OAuth redirect URIs in provider settings:

**Google:**
- Add `https://api.habittracker.example/v1/auth/google/callback`

**GitHub:**
- Update "Authorization callback URL" to `https://api.habittracker.example/v1/auth/github/callback`

### HTTPS Requirement

OAuth flows require HTTPS in production. Use environment variable:

```bash
ENABLE_HTTPS=true
```

### CORS Configuration

Update `CORS_ORIGIN` to include iOS app scheme:

```bash
CORS_ORIGIN=https://api.habittracker.example,habittracker://
```

## References

- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Documentation](https://docs.github.com/en/developers/apps/building-oauth-apps/authorizing-oauth-apps)
- [ASWebAuthenticationSession Documentation](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
