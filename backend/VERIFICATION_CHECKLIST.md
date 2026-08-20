# Backend Verification Checklist

This document outlines the verification steps for the backend implementation.

## Pre-Flight Checks

- [ ] Node.js v18+ installed: `node --version`
- [ ] npm v9+ installed: `npm --version`
- [ ] PostgreSQL v14+ installed: `psql --version`
- [ ] Git repository initialized: `git status`

## Installation & Configuration

- [ ] Dependencies installed: `npm install`
- [ ] `.env` file created from `.env.example`
- [ ] Database created and initialized
- [ ] Environment variables configured

## Code Quality

### TypeScript Type Checking

```bash
npm run typecheck
```

Expected result: No errors

- [ ] All `.ts` files compile without errors
- [ ] All type annotations are valid
- [ ] No implicit `any` types

### Linting

```bash
npm run lint
```

Expected result: No ESLint errors (warnings allowed)

- [ ] Code style is consistent
- [ ] No unused imports
- [ ] No console logs in production code

## Testing

### Unit Tests

```bash
npm run test:health
```

Expected result: All tests pass

- [ ] Health endpoint returns 200 OK
- [ ] Response includes required fields
- [ ] Database connection reported correctly
- [ ] Error handling works properly

### Test Coverage

```bash
npm run test:coverage
```

Expected result: Coverage report generated

- [ ] Lines: > 80%
- [ ] Branches: > 75%
- [ ] Functions: > 80%
- [ ] Statements: > 80%

### All Tests

```bash
npm test
```

Expected result: All tests pass

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] No test hangs or timeouts

## Server Startup

### Development Server

```bash
npm run dev
```

Expected output:
```
[TIMESTAMP] [INFO] Starting Habit Tracker Backend
[TIMESTAMP] [INFO] Configuration validated
[TIMESTAMP] [INFO] Database connection established
[TIMESTAMP] [INFO] Express app created
[TIMESTAMP] [INFO] WebSocket gateway initialized
[TIMESTAMP] [INFO] Server listening on port 3000
```

- [ ] Server starts without errors
- [ ] No warnings in startup logs
- [ ] Process doesn't crash after startup
- [ ] Server is responsive

### Health Endpoint

```bash
curl -X GET http://localhost:3000/health
```

Expected response (200 OK):
```json
{
  "success": true,
  "data": {
    "status": "ok",
    "timestamp": "2026-08-20T...",
    "uptime": 123.456,
    "database": { "connected": true }
  },
  "timestamp": "2026-08-20T..."
}
```

- [ ] Endpoint returns 200 OK
- [ ] Response is valid JSON
- [ ] Success field is true
- [ ] Database connection is reported
- [ ] Timestamp is in ISO 8601 format
- [ ] Multiple calls work consistently

### Error Handling

```bash
curl -X GET http://localhost:3000/nonexistent
```

Expected response (404 NOT_FOUND):
```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Route /nonexistent not found"
  },
  "timestamp": "2026-08-20T..."
}
```

- [ ] Returns 404 status code
- [ ] Error response is properly formatted
- [ ] Error code is meaningful
- [ ] Error message is descriptive

## Production Build

### Build Compilation

```bash
npm run build
```

Expected result: No errors, `dist/` directory created

- [ ] Compiles without errors
- [ ] `dist/` directory contains `.js` files
- [ ] Source maps generated (`.js.map` files)

### Production Start

```bash
NODE_ENV=production npm start
```

Expected result: Server starts with production settings

- [ ] No development logs
- [ ] Server is ready for requests
- [ ] Error handling is production-grade

## Database Verification

### Connection Test

```bash
psql -U postgres -d habit_tracker_dev -c "SELECT NOW();"
```

Expected output: Current timestamp

- [ ] PostgreSQL is running
- [ ] Database is accessible
- [ ] User has proper permissions

### Schema Verification

```bash
psql -U postgres -d habit_tracker_dev -c "\dt"
```

Expected tables:
- users
- habits
- check_ins
- streaks

- [ ] All required tables exist
- [ ] Indexes are created
- [ ] Foreign keys are configured

## Environment Configuration

- [ ] NODE_ENV is set correctly
- [ ] PORT is configured
- [ ] LOG_LEVEL is appropriate
- [ ] DATABASE_URL is valid
- [ ] JWT_SECRET is set (not default)
- [ ] CORS_ORIGIN includes all clients
- [ ] No secrets in `.env.example`
- [ ] `.env` is in `.gitignore`

## Security Checks

- [ ] JWT_SECRET is strong (not "dev-secret")
- [ ] CORS is restricted to known origins
- [ ] No credentials in code
- [ ] Helmet security headers enabled
- [ ] HTTPS ready (for production)
- [ ] Error messages don't leak sensitive info

## Documentation

- [ ] README.md exists and is accurate
- [ ] SETUP.md covers installation steps
- [ ] API.md documents endpoints
- [ ] Environment variables are documented
- [ ] Error codes are documented
- [ ] WebSocket protocol is documented

## Performance

- [ ] Server response time < 100ms for health
- [ ] No memory leaks on repeated requests
- [ ] Database queries are optimized
- [ ] WebSocket connections are stable

## Logging

- [ ] Server startup logs are clear
- [ ] Request logging shows method/path/status
- [ ] Error logging includes stack traces
- [ ] No sensitive data in logs

## Sign-Off

- [ ] All checks completed
- [ ] No critical issues remain
- [ ] Backend ready for feature implementation
- [ ] Ready for iOS integration testing

---

## Quick Verification Commands

Run these in sequence to verify the complete setup:

```bash
# 1. Check Node and npm
node --version && npm --version

# 2. Install dependencies
npm install

# 3. Type checking
npm run typecheck

# 4. Run tests
npm test

# 5. Start server (will hang - press Ctrl+C to stop)
npm run dev

# 6. In another terminal, test health endpoint
curl http://localhost:3000/health
```

## Troubleshooting

If any check fails, refer to SETUP.md or the specific error documentation.
