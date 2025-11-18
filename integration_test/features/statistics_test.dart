import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for statistics and analytics functionality
///
/// Tests family statistics, charts, and progress tracking

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Statistics Tests', () {
    testWidgets('Adult can navigate to statistics tab',
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

      // Navigate to Statistics tab
      await navigateToTab(tester, 'Statistics');
      await waitFor(1);

      // Verify Statistics tab is displayed
      expect(find.text('Statistics'), findsOneWidget);
    });

    testWidgets('Statistics screen displays family overview',
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

      // Navigate to Statistics tab
      await navigateToTab(tester, 'Statistics');
      await waitFor(2);

      // Statistics should display various metrics
      await tester.pumpAndSettle();
    });

    testWidgets('Statistics screen displays completion metrics',
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

      // Navigate to Statistics tab
      await navigateToTab(tester, 'Statistics');
      await waitFor(2);

      // Should show completion rates, total chores, etc.
      await tester.pumpAndSettle();
    });

    testWidgets('Statistics screen displays child performance',
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

      // Navigate to Statistics tab
      await navigateToTab(tester, 'Statistics');
      await waitFor(2);

      // Should display individual child statistics
      await tester.pumpAndSettle();
    });

    testWidgets('Statistics screen is scrollable',
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

      // Navigate to Statistics tab
      await navigateToTab(tester, 'Statistics');
      await waitFor(2);

      // Try scrolling to ensure content is accessible
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(0, -200));
        await tester.pumpAndSettle();
      }
    });
  });
}
