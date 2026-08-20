# Error Handling Guide

## Overview

This guide documents the comprehensive error handling system for the Habit Tracker application across both backend and iOS frontend.

**Principles:**
- ✅ Consistent error response format
- ✅ User-friendly error messages
- ✅ Never expose internal/database errors
- ✅ Proper HTTP status codes
- ✅ Clear recovery suggestions
- ✅ Every screen has error states

---

## Backend Error Handling

### Error Codes & Messages

**File:** `backend/src/utils/errorCodes.ts`

All backend errors are standardized with consistent error codes and user-friendly messages.

#### Authentication Errors (401)

| Error Code | Message | Log Message |
|-----------|---------|-------------|
| `MISSING_TOKEN` | Authentication token is required | Request missing Authorization header |
| `INVALID_TOKEN` | Your session has expired. Please sign in again. | Token verification failed |
| `EXPIRED_TOKEN` | Your session has expired. Please sign in again. | Token has expired |
| `MALFORMED_TOKEN` | Your session is invalid. Please sign in again. | Token format is invalid |

**Example Response:**
```json
{
  "success": false,
  "error": {
    "code": "INVALID_TOKEN",
    "message": "Your session has expired. Please sign in again."
  },
  "timestamp": "2026-08-20T..."
}
```

#### Authorization Errors (403)

| Error Code | Message |
|-----------|---------|
| `FORBIDDEN` | You do not have permission to access this resource. |
| `HABIT_NOT_OWNED` | You do not have access to this habit. |
| `CHECK_IN_NOT_OWNED` | You do not have access to this check-in. |

**Never expose:**
- User IDs
- Database structure
- Other users' data
- Internal implementation details

#### Validation Errors (400)

| Error Code | Message |
|-----------|---------|
| `INVALID_REQUEST` | Your request contains invalid data. Please try again. |
| `INVALID_HABIT_NAME` | Habit name is required and cannot be empty. |
| `INVALID_START_DATE` | Start date cannot be in the future. |
| `INVALID_STATUS` | Invalid habit status. |
| `INVALID_STATUS_TRANSITION` | This habit status change is not allowed. |
| `ARCHIVED_HABIT_READ_ONLY` | Archived habits cannot be modified. |
| `PAUSED_HABIT_NO_CHECKIN` | Cannot check in for paused habits. |
| `ARCHIVED_HABIT_NO_CHECKIN` | Cannot check in for archived habits. |

#### Duplicate Errors (409)

| Error Code | Message |
|-----------|---------|
| `DUPLICATE_CHECK_IN` | You have already completed this habit today. |

#### Not Found Errors (404)

| Error Code | Message |
|-----------|---------|
| `NOT_FOUND` | The requested resource was not found. |
| `HABIT_NOT_FOUND` | Habit not found. |
| `CHECK_IN_NOT_FOUND` | No check-in found for today. |
| `USER_NOT_FOUND` | User not found. |

#### OAuth Errors (400)

| Error Code | Message |
|-----------|---------|
| `INVALID_AUTH_CODE` | Authentication code is invalid or expired. Please try signing in again. |
| `OAUTH_EXCHANGE_FAILED` | Failed to authenticate with the provider. Please try again. |
| `OAUTH_USER_INFO_FAILED` | Failed to retrieve user information. Please try again. |

#### Server Errors (500)

| Error Code | Message |
|-----------|---------|
| `INTERNAL_ERROR` | Something went wrong. Please try again later. |
| `DATABASE_ERROR` | A database error occurred. Please try again later. |
| `TRANSACTION_FAILED` | The operation could not be completed. Please try again. |

### Error Handler Middleware

**File:** `backend/src/middleware/errorHandler.ts`

The error handler ensures:

1. **No Internal Details Exposed**
   - Database errors caught and sanitized
   - Duplicate key constraint errors mapped to user-friendly messages
   - Validation errors provide helpful context
   - Stack traces never returned to client

2. **Consistent Format**
   - All errors return: `{ success, error: { code, message }, timestamp }`
   - HTTP status codes match error types
   - Proper logging for debugging

3. **Database Error Handling**
   ```typescript
   // Duplicate key constraint error
   if (err.message && err.message.includes('duplicate key')) {
     return 409 DUPLICATE_CHECK_IN
   }

   // Generic database error
   if (err.message && err.message.includes('database')) {
     return 500 INTERNAL_ERROR (safe message)
   }
   ```

### HTTP Status Code Mapping

| Status | Use Case |
|--------|----------|
| **400** | Validation errors, invalid requests |
| **401** | Missing/invalid authentication token |
| **403** | User lacks permission (authorization) |
| **404** | Resource not found |
| **409** | Duplicate check-in (conflict) |
| **500** | Server/database errors |

**No internal details in error responses:**
- ❌ SQL queries
- ❌ Database errors
- ❌ File paths
- ❌ Stack traces
- ❌ Internal error codes
- ❌ Configuration details

---

## iOS Error Handling

### User-Facing Error Types

**File:** `HT/Core/Networking/APIErrorHandling.swift`

#### Error Categories

**Network Errors**
```swift
case networkUnavailable
case networkTimeout
case noInternet
```
Messages: Clear action to check internet

**Authentication Errors**
```swift
case sessionExpired
case unauthorized
case invalidCredentials
case authenticationFailed(String)
```
Messages: Always prompt to sign in again

**Server Errors**
```swift
case serverError
case serviceUnavailable
case internalError
```
Messages: Apologetic, non-technical

**Validation Errors**
```swift
case validationFailed(String)
case invalidInput(String)
```
Messages: Explain what went wrong

**Resource Errors**
```swift
case notFound(String)
case duplicate(String)
case cannotDelete(String)
case cannotModify(String)
```
Messages: Context-specific

**Habit-Specific Errors**
```swift
case cannotCheckInArchived
case cannotCheckInPaused
case alreadyCheckedInToday
case cannotUndoCheckIn(String)
```

**WebSocket Errors**
```swift
case webSocketDisconnected
case webSocketAuthFailed
case webSocketError(String)
```

### Error Mapping Functions

**HTTP Status to User Error**
```swift
func mapHTTPStatusToError(_ statusCode: Int, message: String?) -> UserFacingError

// Maps:
// 400 → validationFailed
// 401 → sessionExpired
// 403 → unauthorized
// 404 → notFound
// 409 → duplicate
// 500+ → serverError
```

**API Error Code to User Error**
```swift
func mapAPIErrorCodeToError(_ code: String, message: String) -> UserFacingError

// Maps backend error codes to user-friendly errors
// Examples:
// "DUPLICATE_CHECK_IN" → alreadyCheckedInToday
// "INVALID_TOKEN" → sessionExpired
// "FORBIDDEN" → unauthorized
```

**Network Error Conversion**
```swift
func convertNetworkError(_ error: Error) -> UserFacingError

// Converts NSError domains to user errors
// Examples:
// NSURLErrorNotConnectedToInternet → noInternet
// NSURLErrorTimedOut → networkTimeout
// NSURLErrorCannotConnectToHost → networkUnavailable
```

### Error Components

#### Full Screen Error State

**File:** `HT/Features/Shared/ErrorStateView.swift`

```swift
struct ErrorStateView: View {
  let error: UserFacingError
  let retryAction: (() -> Void)?
  let dismissAction: (() -> Void)?
}
```

**Displays:**
- Icon (contextual to error type)
- Title: "Error"
- Error message (user-friendly)
- Recovery suggestion
- Retry button (if action provided)
- Dismiss button (if action provided)

**Usage:**
```swift
ErrorStateView(
  error: .alreadyCheckedInToday,
  retryAction: { viewModel.checkInToday() },
  dismissAction: { showError = false }
)
```

#### Inline Error View

**File:** `HT/Features/Shared/ErrorStateView.swift`

```swift
struct InlineErrorView: View {
  let error: UserFacingError
  let retryAction: (() -> Void)?
  let dismissAction: (() -> Void)?
}
```

**Displays:**
- Compact error banner
- Icon + message
- Close button
- Optional retry link

**Usage:** Embedded in screens alongside other content

#### Loading or Error View

**File:** `HT/Features/Shared/ErrorStateView.swift`

```swift
struct LoadingOrErrorView<Content: View>: View {
  let isLoading: Bool
  let error: UserFacingError?
  let retryAction: (() -> Void)?
  let content: () -> Content
}
```

**States:**
- **Loading:** Shows spinner + "Loading..." text
- **Error:** Shows ErrorStateView
- **Success:** Shows content

**Usage:** Wraps screens with multiple states

---

## Screen Error States

### LoginView

**Error States:**
- Network unavailable → Show network error with retry
- Server error → Show generic error with retry
- Invalid credentials → Show authentication failed with retry
- Authentication cancelled → Allow retry

**Recovery:**
- Retry button triggers OAuth flow again
- Dismiss allows manual retry

### DashboardView (Habits List)

**Error States:**
- Loading failed → ErrorStateView with retry
- Network timeout → ErrorStateView with retry
- Empty state (when no errors but no habits) → Different message

**Always shows:**
- ✅ Loading state (spinner)
- ✅ Error state (ErrorStateView)
- ✅ Empty state (message)
- ✅ Success state (list)

### HabitDetailView

**Error States:**
- Habit not found → ErrorStateView
- Failed to load details → ErrorStateView with retry
- Check-in failed → InlineErrorView
- Undo failed → InlineErrorView

**Per-action errors:**
- Stored separately (not blocking screen)
- Shown near affected action

### HabitFormView (Create/Edit)

**Error States:**
- Validation errors → InlineErrorView per field
- Submit failed → ErrorStateView

**User guidance:**
- Field-level validation messages
- Submit error explained

### SettingsView

**Error States:**
- Logout failed → ErrorStateView with retry

### WebSocket Errors

**When WebSocket connects:**
- ✅ Show connected state
- ❌ Handle disconnection gracefully
- ⚠️ Show banner if notifications unavailable

**Error states:**
- Disconnected → Show banner with reconnect status
- Auth failed → Prompt to sign in again
- Message error → Log silently, don't disrupt UI

---

## Error Testing

### Backend Error Tests

**File:** `backend/tests/integration/errorHandling.test.ts`

Covers:
- ✅ Authentication errors (401)
- ✅ Authorization errors (403)
- ✅ Validation errors (400)
- ✅ Not found errors (404)
- ✅ Duplicate errors (409)
- ✅ Server errors (500)
- ✅ Consistent response format
- ✅ No internal details exposed
- ✅ Correct HTTP status codes

### iOS Error Tests

**File:** `HTTests/ErrorHandlingTests.swift`

Covers:
- ✅ Error message generation
- ✅ HTTP status mapping
- ✅ API error code mapping
- ✅ Network error conversion
- ✅ No internal details exposed
- ✅ Recovery suggestions present
- ✅ Error equality

---

## Best Practices

### Backend

1. **Always use AppError** for consistency
   ```typescript
   throw new AppError('INVALID_REQUEST', 400, 'User-friendly message');
   ```

2. **Log internal details** for debugging
   ```typescript
   logger.error('Database error', {
     message: err.message,
     stack: err.stack,
     userId: req.userId
   });
   ```

3. **Return safe messages** to clients
   ```typescript
   // Bad: return err.message (exposes internals)
   // Good: throw new AppError(..., 'A database error occurred...')
   ```

4. **Use error codes** for mobile to understand
   ```typescript
   {
     "error": {
       "code": "DUPLICATE_CHECK_IN",  // Mobile can handle this
       "message": "Already completed today"
     }
   }
   ```

### iOS

1. **Always catch and map errors**
   ```swift
   do {
     let result = try await API.checkIn(habitId)
   } catch {
     let userError = mapError(error)
     showErrorView(userError)
   }
   ```

2. **Provide recovery context**
   ```swift
   // Good: error includes suggestion
   UserFacingError.sessionExpired
   // Message: "Your session has expired..."
   // Suggestion: "Please sign in again to continue."
   ```

3. **Show loading states**
   ```swift
   LoadingOrErrorView(isLoading: vm.isLoading, error: vm.error) {
     // Success content
   }
   ```

4. **Never display raw errors**
   ```swift
   // Bad: Text(error.localizedDescription)
   // Good: Text(userFacingError.errorDescription ?? "Error")
   ```

---

## Error Flow Examples

### Check-in Failed (Duplicate)

**Sequence:**
1. User taps check-in button
2. Button shows loading state
3. API returns 409 with `DUPLICATE_CHECK_IN`
4. iOS maps to `UserFacingError.alreadyCheckedInToday`
5. InlineErrorView shows: "You have already completed this habit today."
6. Suggestion: "You can only check in once per day."
7. Dismiss button clears error

### Session Expired

**Sequence:**
1. User makes API call
2. Backend returns 401 with `INVALID_TOKEN`
3. iOS maps to `UserFacingError.sessionExpired`
4. Screen shows ErrorStateView
5. Message: "Your session has expired. Please sign in again."
6. Suggestion: "Please sign in again to continue."
7. Retry button triggers OAuth flow

### Network Error

**Sequence:**
1. iOS cannot reach backend
2. NSURLError caught
3. Converted to `UserFacingError.noInternet`
4. ErrorStateView shows: "No internet connection..."
5. Suggestion: "Check your internet connection and try again."
6. Retry button retries request

---

## Rollout Checklist

- [ ] All backend errors use AppError
- [ ] All errors have user-friendly messages
- [ ] No internal details exposed
- [ ] HTTP status codes correct
- [ ] iOS maps HTTP status to UserFacingError
- [ ] iOS maps API error codes to UserFacingError
- [ ] Every screen has loading state
- [ ] Every screen has error state
- [ ] Every screen has empty state
- [ ] ErrorStateView integrated on all screens
- [ ] Error recovery suggestions present
- [ ] Backend error tests passing
- [ ] iOS error tests passing
- [ ] Manual testing of error scenarios
- [ ] Errors don't block UI (except for critical ones)
- [ ] WebSocket errors handled gracefully

---

## Documentation

- `ERROR_HANDLING_GUIDE.md` — This file
- `backend/src/utils/errorCodes.ts` — Error code definitions
- `backend/src/middleware/errorHandler.ts` — Error handler middleware
- `HT/Core/Networking/APIErrorHandling.swift` — iOS error types and mapping
- `HT/Features/Shared/ErrorStateView.swift` — iOS error UI components
- `backend/tests/integration/errorHandling.test.ts` — Backend error tests
- `HTTests/ErrorHandlingTests.swift` — iOS error tests

---

**Status:** ✅ Complete error handling system implemented
**Last Updated:** 2026-08-20
