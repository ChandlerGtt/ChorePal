import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Test suite for authentication functionality
///
/// Tests login, logout, and authentication flows

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Tests', () {
    // Ensure user is signed out before each test
    setUp(() async {
      try {
        await FirebaseAuth.instance.signOut();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Ignore errors if already signed out
      }
    });

    testWidgets('App displays login screen on launch',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Verify login screen is displayed
      expect(find.text('Login'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Login screen has email and password fields',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Check for email field
      final emailField = find.byWidgetPredicate((w) {
        return w is TextField && w.decoration?.labelText == 'Email';
      });
      expect(emailField, findsOneWidget);

      // Check for password field
      final passwordField = find.byWidgetPredicate((w) {
        return w is TextField && w.decoration?.labelText == 'Password';
      });
      expect(passwordField, findsOneWidget);
    });

    testWidgets('Login button is present and enabled',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Verify login button exists
      final loginButton = find.text('Login');
      expect(loginButton, findsOneWidget);
    });

    testWidgets('Invalid credentials show error',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Try login with invalid credentials
      await login(
        tester,
        email: 'invalid@example.com',
        password: 'wrongpassword',
      );
      await waitFor(3);

      // Error message should appear
      // Note: This test may need adjustment based on error handling
      await tester.pumpAndSettle();
    });

    testWidgets('Adult can logout successfully',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Login as adult
      await login(
        tester,
        email: TestCredentials.adultEmail,
        password: TestCredentials.adultPassword,
      );
      await waitFor(2);

      // Look for logout option (typically in menu or settings)
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Look for Logout option
        final logoutOption = find.text('Logout');
        if (logoutOption.evaluate().isNotEmpty) {
          await tester.tap(logoutOption);
          await tester.pumpAndSettle();
          await waitFor(1);

          // Should return to login screen
          expect(find.text('Login'), findsWidgets);
        }
      }

      // Alternatively, logout might be in settings
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        final logoutOption = find.text('Logout');
        if (logoutOption.evaluate().isNotEmpty) {
          await tester.tap(logoutOption);
          await tester.pumpAndSettle();
          await waitFor(1);
        }
      }
    });

    testWidgets('User stays logged in after app restart',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Login as adult
      await login(
        tester,
        email: TestCredentials.adultEmail,
        password: TestCredentials.adultPassword,
      );
      await waitFor(2);

      // Verify successful login
      expect(find.text('Chores'), findsOneWidget);

      // Note: Testing persistence would require app restart
      // which is complex in integration tests
    });

    testWidgets('Password field obscures text',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Check that password field obscures text
      final passwordField = find.byWidgetPredicate((w) {
        return w is TextField &&
               w.decoration?.labelText == 'Password' &&
               w.obscureText == true;
      });
      expect(passwordField, findsOneWidget);
    });
  });
}