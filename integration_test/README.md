# Integration Tests

This directory contains integration tests for the ChorePal application, organized for clarity and maintainability.

## Structure

```
integration_test/
├── app_test.dart                    # Main test suite runner
├── helpers/
│   ├── test_helpers.dart           # Common utilities and helper functions
│   └── mock_data.dart              # Test data and credentials
├── auth/
│   ├── adult_login_test.dart       # Adult authentication tests
│   └── child_login_test.dart       # Child authentication tests
├── features/
│   ├── adult_tab_test.dart         # Adult tab navigation tests
│   ├── adult_modules_test.dart     # Adult-specific feature tests
│   └── child_modules_test.dart     # Child-specific feature tests
└── e2e/
    └── full_user_flow_test.dart    # End-to-end user flow scenarios
```

## Running Tests

### Run all integration tests
```bash
flutter test integration_test/app_test.dart
```

### Run specific test suites
```bash
# Auth tests
flutter test integration_test/auth/adult_login_test.dart
flutter test integration_test/auth/child_login_test.dart

# Feature tests
flutter test integration_test/features/adult_tab_test.dart
flutter test integration_test/features/adult_modules_test.dart
flutter test integration_test/features/child_modules_test.dart

# E2E tests
flutter test integration_test/e2e/full_user_flow_test.dart
```

## Test Organization

### Helpers (`helpers/`)
- **test_helpers.dart**: Contains reusable helper functions like `login()`, `navigateToTab()`, `waitFor()`, etc.
- **mock_data.dart**: Contains test credentials and mock data used across tests

### Auth (`auth/`)
Tests for authentication flows:
- Adult login
- Child login

### Features (`features/`)
Tests for specific features and modules:
- Tab navigation
- Adult-specific modules (chore management, statistics, etc.)
- Child-specific modules (viewing/completing chores, rewards, etc.)

### E2E (`e2e/`)
End-to-end tests that simulate complete user workflows:
- Full adult workflow (login → navigate → perform actions)
- Full child workflow (login → complete chores → view rewards)

## Test Credentials

Test credentials are defined in `helpers/mock_data.dart`:

**Adult User:**
- Email: john@example.com
- Password: password!1234

**Child User:**
- Email: child@example.com
- Password: childpass123

## Adding New Tests

1. Create test file in appropriate directory
2. Import helpers: `import '../helpers/test_helpers.dart';`
3. Import mock data: `import '../helpers/mock_data.dart';`
4. Add test import to `app_test.dart` if you want it in the main suite
5. Follow existing patterns for consistency

## Notes

- Some tests are marked with `skip: true` pending implementation
- Use `group()` to organize related tests
- Use descriptive test names that explain what is being tested
- Add comments to explain complex test logic
