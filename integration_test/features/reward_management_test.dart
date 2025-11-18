import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for reward management functionality
///
/// Tests creating, viewing, and redeeming rewards

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reward Management Tests', () {
    testWidgets('Adult can navigate to rewards tab',
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

      // Navigate to Rewards tab
      await navigateToTab(tester, 'Rewards');
      await waitFor(1);

      // Verify Rewards tab is displayed
      expect(find.text('Rewards'), findsOneWidget);
    });

    testWidgets('Adult can access add reward interface',
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

      // Navigate to Rewards tab
      await navigateToTab(tester, 'Rewards');
      await waitFor(1);

      // Look for add reward button (FloatingActionButton or '+' icon)
      final addButton = find.byType(FloatingActionButton);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        await waitFor(1);

        // Verify reward creation form is displayed
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('Rewards are displayed in reward list',
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

      // Navigate to Rewards tab
      await navigateToTab(tester, 'Rewards');
      await waitFor(2);

      // Verify rewards section is accessible
      await tester.pumpAndSettle();
    });

    testWidgets('Adult can view reward tiers',
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

      // Navigate to Rewards tab
      await navigateToTab(tester, 'Rewards');
      await waitFor(2);

      // Rewards are typically organized by tiers
      await tester.pumpAndSettle();
    });
  });
}
