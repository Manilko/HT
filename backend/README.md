# Habit Tracker Backend

Node.js/TypeScript REST API and WebSocket server for the Habit Tracker application.

## Architecture

### Module Structure

- **auth/**: OAuth 2.0 authentication (Google, GitHub), JWT token generation
- **users/**: User management and profile operations
- **habits/**: Habit CRUD operations
- **check-ins/**: Daily habit check-in logging
- **streaks/**: Streak calculation and milestone tracking
- **websocket/**: Real-time notifications via WebSocket

### Key Concepts

- **Service Layer**: Business logic (StreakService, OAuthService, etc.)
- **Repository Layer**: Data access (HabitsRepository, UsersRepository, etc.)
- **Controller Layer**: HTTP request handling
- **Middleware**: Authentication, error handling, logging
- **Types**: TypeScript interfaces for type safety

## Setup

See `GETTING_STARTED.md` in docs/

## API Documentation

See `docs/API.md` for full endpoint documentation.

## WebSocket Protocol

See `docs/WEBSOCKET.md` for WebSocket event specification.

## Database Schema

See `docs/DATABASE.md` for schema details.

## Testing

Unit tests in `tests/unit/`
Integration tests in `tests/integration/`

Run with: `npm test`

## Development

- Use TypeScript strict mode
- Follow the service/repository pattern
- Write tests for new features
- Keep modules loosely coupled
