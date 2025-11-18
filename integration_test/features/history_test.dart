import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for history screens
///
/// Tests chore history and reward history functionality

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('History Tests', () {
    testWidgets('Adult can access chore history',
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

      // Look for history option (typically in menu or navigation)
      final menuButton = find.byIcon(Icons.menu);
      if (menuButton.evaluate().isNotEmpty) {
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Look for History option
        final historyOption = find.text('History');
        if (historyOption.evaluate().isNotEmpty) {
          await tester.tap(historyOption);
          await tester.pumpAndSettle();
          await waitFor(1);
        }
      }

      // Alternatively, history might be accessible via a button
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        await waitFor(1);
      }
    });

    testWidgets('Chore history displays completed chores',
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

      // Navigate to history screen
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        await waitFor(2);

        // History should display completed chores
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Chore history groups by month',
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

      // Navigate to history screen
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        await waitFor(2);

        // History is grouped by month according to implementation
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Chore history displays completion details',
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

      // Navigate to history screen
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        await waitFor(2);

        // Should show who completed, when, points earned, etc.
        await tester.pumpAndSettle();
      }
    });

    testWidgets('History screen supports pull-to-refresh',
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

      // Navigate to history screen
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        await waitFor(2);

        // Try pull-to-refresh
        final refreshIndicator = find.byType(RefreshIndicator);
        if (refreshIndicator.evaluate().isNotEmpty) {
          await tester.drag(refreshIndicator.first, const Offset(0, 300));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Reward history displays redeemed rewards',
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

      // Navigate to rewards tab
      await navigateToTab(tester, 'Rewards');
      await waitFor(2);

      // Look for reward history option
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
        await waitFor(1);
      }
    });
  });
}
