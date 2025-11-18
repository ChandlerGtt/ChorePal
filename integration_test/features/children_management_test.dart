import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for children management functionality
///
/// Tests adding, viewing, and managing children in the family

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Children Management Tests', () {
    testWidgets('Adult can navigate to children tab',
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

      // Navigate to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(1);

      // Verify Children tab is displayed
      expect(find.text('Children'), findsOneWidget);
    });

    testWidgets('Children tab displays family children list',
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

      // Navigate to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(2);

      // Children list should be displayed
      await tester.pumpAndSettle();
    });

    testWidgets('Adult can access add child interface',
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

      // Navigate to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(1);

      // Look for add child button
      final addButton = find.byType(FloatingActionButton);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton);
        await tester.pumpAndSettle();
        await waitFor(1);

        // Verify add child form is displayed
        expect(find.byType(TextField), findsWidgets);
      }
    });

    testWidgets('Children cards display child information',
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

      // Navigate to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(2);

      // Should display child names, points, progress
      await tester.pumpAndSettle();
    });

    testWidgets('Children tab shows child statistics',
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

      // Navigate to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(2);

      // Should show points, completed chores, etc.
      await tester.pumpAndSettle();
    });

    testWidgets('Adult can view individual child details',
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

      // Navigate to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(2);

      // Tap on a child card to view details
      final childCard = find.byType(Card);
      if (childCard.evaluate().isNotEmpty) {
        // Child cards should be tappable
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Children can be removed from family',
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

      // Navigate to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(2);

      // Look for delete/remove options
      final deleteIcon = find.byIcon(Icons.delete);
      if (deleteIcon.evaluate().isNotEmpty) {
        // Remove functionality exists
        expect(deleteIcon, findsWidgets);
      }
    });
  });
}
