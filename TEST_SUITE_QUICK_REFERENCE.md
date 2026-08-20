# Test Suite Quick Reference

## Running Tests

### Backend Tests (with Node.js)
```bash
cd backend
npm install
npm test                                    # Run all tests
npm test -- tests/integration/auth.routes  # Run specific test
npm run test:coverage                       # With coverage
npm run test:watch                          # Watch mode
```

### iOS Tests (in Xcode)
```bash
# Open project
open HT.xcodeproj

# Run all tests
Cmd + U

# Run specific test class
Cmd + U (with test file open)

# Run with coverage
Product → Scheme → Edit Scheme → Test → Code Coverage
```

---

## Test Coverage Quick Stats

### Backend
| Component | Tests | File |
|-----------|-------|------|
| Authentication | 12 | auth.routes.test.ts |
| Habits CRUD | 23 | habits.routes.test.ts |
| Check-ins | 15 | checkIns.routes.test.ts |
| Authorization | 22 | authorization.test.ts |
| Error Handling | 30+ | errorHandling.test.ts |
| Streaks | 20+ | streakService.test.ts |
| WebSocket | 10+ | websocket.handler.test.ts |
| Database | 30+ | database.constraints.test.ts |
| **Total** | **100+** | **14 files** |

### iOS
| Component | Tests | File |
|-----------|-------|------|
| Authentication | 7 | AuthenticationTests.swift |
| Habits | 22 | HabitListViewModelTests.swift |
| Check-ins | 13 | CheckInRepositoryTests.swift |
| Streaks | 9 | ComprehensiveIOSTestSuite.swift |
| WebSocket | 15 | WebSocketServiceTests.swift |
| Error Handling | 35+ | ErrorHandlingTests.swift |
| Other (Dashboard, Logout, Notifications) | 15+ | Multiple files |
| **Total** | **117+** | **11 files** |

---

## Key Features

### No External Dependencies
- ✅ Backend: OAuth providers mocked (no Google/GitHub calls)
- ✅ iOS: API client mocked (no real backend calls)
- ✅ iOS: WebSocket mocked (no real connections)
- ✅ iOS: Storage mocked (no Keychain access)

### Test Isolation
- ✅ Backend: Database cleanup after each test
- ✅ iOS: Fresh mocks for each test
- ✅ All tests independent and can run in any order

### Security Testing
- ✅ 22 authorization boundary tests
- ✅ User A/B isolation verified
- ✅ Token validation on every request
- ✅ 14 security requirements verified

### Error Coverage
- ✅ 35 standardized error codes
- ✅ All HTTP status codes tested (400, 401, 403, 404, 409, 500)
- ✅ User-friendly error messages
- ✅ No internal details exposed

---

## Documentation Files

| File | Purpose |
|------|---------|
| `SECURITY_AUDIT_REPORT.md` | All 14 security requirements verified |
| `ERROR_HANDLING_GUIDE.md` | Error handling reference guide |
| `BACKEND_TEST_SUITE_SUMMARY.md` | Backend test details |
| `IOS_TEST_SUITE_SUMMARY.md` | iOS test details |
| `IMPLEMENTATION_STATUS_2026_08_20.md` | Complete status report |
| `COMPLETE_TEST_SUITE_STATUS.md` | Combined backend + iOS status |
| `FINAL_PROJECT_SUMMARY.md` | Full project overview |

---

## Test Patterns

### Backend Test Pattern
```typescript
describe('Feature', () => {
  beforeAll(async () => {
    // Setup: Run migrations
  });

  afterEach(async () => {
    // Cleanup: TRUNCATE tables
  });

  it('should do something', async () => {
    const res = await request(app)
      .post('/v1/endpoint')
      .send(testData);
    
    expect(res.status).toBe(200);
  });
});
```

### iOS Test Pattern
```swift
final class FeatureTests: XCTestCase {
  var sut: FeatureClass!
  var mockService: MockService!

  override func setUp() {
    super.setUp()
    mockService = MockService()
    sut = FeatureClass(service: mockService)
  }

  override func tearDown() {
    sut = nil
    mockService = nil
    super.tearDown()
  }

  @MainActor
  func testFeature() async {
    mockService.result = expectedResult
    await sut.performAction()
    XCTAssertEqual(mockService.callCount, 1)
  }
}
```

---

## Mocking Services

### Backend
- OAuth providers: Mocked HTTP responses
- External APIs: Mocked responses
- Database: Real PostgreSQL (isolated per test)

### iOS
- API Client: Mocked HTTP requests
- WebSocket: Mocked connection & messages
- Storage Manager: In-memory storage
- Repositories: In-memory data

---

## Debugging Tests

### Backend
```bash
# Run single test file
npm test -- auth.routes.test.ts

# Run with verbose output
npm test -- --verbose

# Run with specific pattern
npm test -- --testNamePattern="Google"
```

### iOS
```
# In Xcode
Product → Test → [test name]

# Or edit scheme for specific test class
```

---

## Key Test Files

### Backend (Most Important)
1. `authorization.test.ts` — User isolation (22 tests)
2. `errorHandling.test.ts` — Error scenarios (30+ tests)
3. `auth.routes.test.ts` — Authentication (12 tests)
4. `habits.routes.test.ts` — CRUD operations (23 tests)

### iOS (Most Important)
1. `ComprehensiveIOSTestSuite.swift` — Complete coverage (66 tests)
2. `ErrorHandlingTests.swift` — Error scenarios (35+ tests)
3. `WebSocketServiceTests.swift` — WebSocket (15 tests)
4. `HabitListViewModelTests.swift` — Habits (22 tests)

---

## Test Execution Tips

### Backend
- Tests run in parallel by default
- Use `--runInBand` flag if needed for sequential execution
- Coverage reports in `coverage/` directory
- HTML coverage report: `coverage/index.html`

### iOS
- Tests run on main thread (proper for UI tests)
- Use `@MainActor` for UI test methods
- Use `async/await` for async operations
- Coverage data in Xcode Reports Navigator

---

## Continuous Integration

Both test suites support:
- ✅ GitHub Actions
- ✅ GitLab CI
- ✅ Jenkins
- ✅ CircleCI
- ✅ Xcode Cloud (iOS)

Tests are:
- Fully automated (no user input required)
- Deterministic (same results every run)
- Fast (complete in < 5 minutes)
- Portable (run on any machine)

---

## Verification Checklist

Before deployment, verify:
- [ ] Backend: `npm test` passes (all 100+ tests)
- [ ] iOS: `Cmd+U` passes (all 117+ tests)
- [ ] Backend coverage: >80%
- [ ] iOS coverage: >75%
- [ ] No flaky tests (run twice, same results)
- [ ] All documentation up to date
- [ ] Git commits clean

---

## Quick Start (for new developers)

1. **Understanding Backend Tests**
   - Read: `BACKEND_TEST_SUITE_SUMMARY.md`
   - Run: `npm test` to see tests in action
   - Browse: `backend/tests/` directory

2. **Understanding iOS Tests**
   - Read: `IOS_TEST_SUITE_SUMMARY.md`
   - Run: `Cmd+U` in Xcode
   - Browse: `HTTests/` directory

3. **Understanding Security**
   - Read: `SECURITY_AUDIT_REPORT.md`
   - Review: `authorization.test.ts`
   - Check: `ErrorHandlingTests.swift`

4. **Understanding Error Handling**
   - Read: `ERROR_HANDLING_GUIDE.md`
   - Review: `errorCodes.ts` (backend)
   - Check: `APIErrorHandling.swift` (iOS)

---

## Support

For questions about tests:
1. Check documentation files (see above)
2. Review test comments (inline documentation)
3. Look at existing test patterns
4. Check git commit history for context

---

**Last Updated:** 2026-08-20  
**Version:** 1.0.0  
**Status:** ✅ Production Ready
