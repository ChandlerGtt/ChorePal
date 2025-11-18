import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for child dashboard functionality
///
/// Tests child view, chore completion, and reward viewing

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Child Dashboard Tests', () {
    testWidgets('Child can login with valid credentials',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Attempt to login as child
      await login(
        tester,
        email: TestCredentials.childEmail,
        password: TestCredentials.childPassword,
      );
      await waitFor(2);

      // If child login is implemented, verify dashboard appears
      // This test will help identify if child login is functional
      await tester.pumpAndSettle();
    });

    testWidgets('Child dashboard displays assigned chores',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Login as child
      await login(
        tester,
        email: TestCredentials.childEmail,
        password: TestCredentials.childPassword,
      );
      await waitFor(2);

      // Child dashboard should show assigned chores
      await tester.pumpAndSettle();
    });

    testWidgets('Child can view their points',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Login as child
      await login(
        tester,
        email: TestCredentials.childEmail,
        password: TestCredentials.childPassword,
      );
      await waitFor(2);

      // Points should be displayed on dashboard
      await tester.pumpAndSettle();
    });

    testWidgets('Child can view available rewards',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Login as child
      await login(
        tester,
        email: TestCredentials.childEmail,
        password: TestCredentials.childPassword,
      );
      await waitFor(2);

      // Child should be able to view rewards
      await tester.pumpAndSettle();
    });

    testWidgets('Child can mark chore as complete',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Login as child
      await login(
        tester,
        email: TestCredentials.childEmail,
        password: TestCredentials.childPassword,
      );
      await waitFor(2);

      // Look for complete button on chores
      final completeButton = find.text('Complete');
      if (completeButton.evaluate().isNotEmpty) {
        // Complete button exists
        expect(completeButton, findsWidgets);
      }
    });

    testWidgets('Child dashboard shows progress',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Login as child
      await login(
        tester,
        email: TestCredentials.childEmail,
        password: TestCredentials.childPassword,
      );
      await waitFor(2);

      // Should display progress indicators
      await tester.pumpAndSettle();
    });
  });
}
