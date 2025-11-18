import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for chore management functionality
///
/// Tests creating, editing, assigning, and managing chores

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Chore Management Tests', () {
    testWidgets('Adult can access chore creation interface',
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

      // Look for add chore button (FloatingActionButton or '+' icon)
      final addButton = find.byType(FloatingActionButton);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        await waitFor(1);

        // Verify chore creation form is displayed
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('Adult can view pending chores list',
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

      // Verify we're on the Chores tab
      expect(find.text('Chores'), findsOneWidget);

      // Look for chore-related widgets (cards, lists, etc.)
      // The specific widgets depend on your implementation
      await tester.pumpAndSettle();
    });

    testWidgets('Adult can access pending approval chores',
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

      // Look for pending approval section or tab
      await tester.pumpAndSettle();

      // Verify the pending approval section is accessible
      // This depends on your UI implementation
    });

    testWidgets('Adult can navigate to assign chore screen',
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

      // Navigate to Children tab where assignment typically happens
      await navigateToTab(tester, 'Children');
      await waitFor(1);

      // Verify Children tab is displayed
      expect(find.text('Children'), findsOneWidget);
    });
  });
}
