# Habit Tracker - Getting Started

## Project Structure

This is a full-stack application with three main components:

- **iOS**: Native Swift/SwiftUI application
- **Backend**: Node.js/TypeScript REST API with WebSocket support
- **Docs**: Architecture and implementation documentation

## Backend Setup

### Prerequisites
- Node.js 18+
- PostgreSQL 14+
- npm or yarn

### Installation

```bash
cd backend
npm install
```

### Environment Setup

```bash
cp .env.example .env
# Edit .env with your configuration
```

### Development

```bash
npm run dev
```

### Testing

```bash
npm test
npm run test:coverage
```

### Building

```bash
npm run build
npm start
```

## iOS Setup

### Prerequisites
- Xcode 14.3+
- iOS 14.0+
- Swift 5.8+

### Opening the Project

```bash
open HT.xcodeproj
```

### Running the App

1. Select a simulator or device in Xcode
2. Press `Cmd + R` to build and run

### Testing

```
Cmd + U to run tests
```

## Database

PostgreSQL database initialization scripts are in `backend/migrations/`.

## Authentication

The application uses OAuth 2.0 with Google and GitHub providers.

See `ARCHITECTURE.md` and `docs/AUTH.md` for detailed information.

## Next Steps

1. Review `ARCHITECTURE.md` for the complete technical design
2. Check `docs/API.md` for API endpoint documentation
3. Check `docs/WEBSOCKET.md` for WebSocket protocol details
4. Implement backend business logic following the modular structure
5. Implement iOS views and ViewModels
6. Write and run tests
