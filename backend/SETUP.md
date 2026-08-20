# Habit Tracker Backend Setup Guide

## Prerequisites

- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher
- **PostgreSQL**: v14.0 or higher
- **TypeScript**: v5.0 or higher (installed via npm)

## Installation & Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Setup Environment Variables

```bash
cp .env.example .env
```

Then edit `.env` with your local development values:

```env
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/habit_tracker_dev
JWT_SECRET=dev-secret-key-change-in-production
CORS_ORIGIN=http://localhost:3000,habittracker://
```

### 3. Initialize Database

#### Option A: Using psql (Recommended)

```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE habit_tracker_dev;

# Connect to the database
\c habit_tracker_dev

# Run initialization script
\i scripts/init-db.sql
```

#### Option B: Using Node.js

```bash
npm run db:init
```

### 4. Type Checking

```bash
npm run typecheck
```

All TypeScript files should compile without errors.

### 5. Run Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run only health endpoint tests
npm run test:health

# Generate coverage report
npm run test:coverage
```

### 6. Start Development Server

```bash
npm run dev
```

Expected output:
```
[2026-08-20T10:00:00.000Z] [INFO] Starting Habit Tracker Backend
[2026-08-20T10:00:00.100Z] [INFO] Configuration validated
[2026-08-20T10:00:00.200Z] [INFO] Database connection established
[2026-08-20T10:00:00.300Z] [INFO] Express app created
[2026-08-20T10:00:00.400Z] [INFO] WebSocket gateway initialized
[2026-08-20T10:00:00.500Z] [INFO] Server listening on port 3000
```

### 7. Verify Health Endpoint

```bash
curl -X GET http://localhost:3000/health
```

Expected response:
```json
{
  "success": true,
  "data": {
    "status": "ok",
    "timestamp": "2026-08-20T10:00:00.000Z",
    "uptime": 5.123,
    "database": {
      "connected": true
    }
  },
  "timestamp": "2026-08-20T10:00:00.000Z"
}
```

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── app.ts              # Express app setup
│   │   ├── env.ts              # Environment configuration
│   │   ├── database.ts         # PostgreSQL connection
│   │   └── logger.ts           # Logging utility
│   ├── middleware/
│   │   ├── errorHandler.ts     # Error handling
│   │   └── requestLogger.ts    # Request logging
│   ├── routes/
│   │   └── health.ts           # Health check endpoint
│   ├── websocket/
│   │   └── index.ts            # WebSocket gateway
│   ├── utils/
│   │   └── tokenUtils.ts       # JWT utilities
│   └── server.ts               # Server entry point
├── tests/
│   ├── unit/
│   │   └── health.test.ts
│   └── integration/
│       └── health.routes.test.ts
├── scripts/
│   └── init-db.sql             # Database initialization
├── package.json                # Dependencies
├── tsconfig.json               # TypeScript configuration
├── jest.config.js              # Jest testing configuration
├── .env.example                # Environment template
└── .gitignore                  # Git ignore rules
```

## Available Scripts

```bash
# Development
npm run dev              # Start dev server with ts-node

# Build & Production
npm run build           # Compile TypeScript to JavaScript
npm start               # Run compiled JavaScript

# Testing
npm test                # Run all tests once
npm run test:watch      # Run tests in watch mode
npm run test:health     # Run health endpoint tests
npm run test:coverage   # Generate coverage report

# Code Quality
npm run typecheck       # Check TypeScript types
npm run lint            # Run ESLint

# Database
npm run migrate         # Run database migrations (future)
```

## API Endpoints

### Health Check

```
GET /health

Response (200 OK):
{
  "success": true,
  "data": {
    "status": "ok",
    "timestamp": "2026-08-20T10:00:00Z",
    "uptime": 123.456,
    "database": { "connected": true }
  },
  "timestamp": "2026-08-20T10:00:00Z"
}
```

### Status Endpoints (Placeholders)

```
GET /v1/auth          - Authentication module
GET /v1/users         - Users module
GET /v1/habits        - Habits module
```

## WebSocket Connection

### Connect

```
wss://localhost:3000/ws?token=<jwt_token>
```

### Events

**Client to Server:**
- `subscribe_milestone` - Subscribe to habit milestone notifications
- `unsubscribe_milestone` - Unsubscribe from habit
- `ping` - Keep-alive ping

**Server to Client:**
- `milestone_reached` - Milestone notification
- `pong` - Keep-alive response
- `error` - Error message

## Error Handling

The backend uses standardized error responses:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {}
  },
  "timestamp": "2026-08-20T10:00:00Z"
}
```

Common error codes:
- `NOT_FOUND` - Resource not found (404)
- `UNAUTHORIZED` - Authentication required (401)
- `FORBIDDEN` - Insufficient permissions (403)
- `INVALID_INPUT` - Validation error (400)
- `INTERNAL_SERVER_ERROR` - Server error (500)

## Database Migrations

Run manually using psql:

```bash
psql -U postgres -d habit_tracker_dev -f scripts/init-db.sql
```

## Troubleshooting

### Database Connection Error

```
Error: connect ECONNREFUSED 127.0.0.1:5432
```

**Solution**: Ensure PostgreSQL is running:
```bash
# macOS
brew services start postgresql

# Linux
sudo systemctl start postgresql

# Windows
pg_ctl -D "C:\Program Files\PostgreSQL\data" start
```

### Port Already in Use

```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution**: Change PORT in `.env` or kill the process:
```bash
# Find process on port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>
```

### TypeScript Errors

```
error TS2307: Cannot find module '@config/env'
```

**Solution**: Ensure `tsconfig.json` path mappings are correct and run:
```bash
npm run typecheck
```

## Development Workflow

1. **Start the server**: `npm run dev`
2. **Watch for TypeScript errors**: `npm run typecheck` (in another terminal)
3. **Run tests**: `npm test` or `npm run test:watch`
4. **Test endpoints**: Use curl, Postman, or REST Client

## Production Deployment

1. **Build**: `npm run build`
2. **Check types**: `npm run typecheck`
3. **Run tests**: `npm test`
4. **Set production env**: `NODE_ENV=production`
5. **Configure secrets**: Set all `.env` variables securely (use environment variables, not files)
6. **Start**: `npm start`

## Next Steps

- [ ] Implement OAuth authentication endpoints
- [ ] Implement habits CRUD endpoints
- [ ] Implement check-ins endpoints
- [ ] Implement streak calculation
- [ ] Implement WebSocket milestone notifications
- [ ] Add database migrations
- [ ] Add more comprehensive tests
- [ ] Set up CI/CD pipeline

## Support

For issues or questions, refer to:
- `docs/API.md` - API documentation
- `docs/AUTH.md` - Authentication flow
- `docs/DATABASE.md` - Database schema
- `docs/WEBSOCKET.md` - WebSocket protocol
