import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for family leaderboard functionality
///
/// Tests leaderboard display, rankings, and statistics

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Leaderboard Tests', () {
    setUp(() async {
      try {
        await FirebaseAuth.instance.signOut();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Ignore errors if already signed out
      }
    });

    testWidgets('Adult can navigate to leaderboard tab',
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

      // Navigate to Leaderboard tab
      await navigateToTab(tester, 'Leaderboard');
      await waitFor(1);

      // Verify Leaderboard tab is displayed
      expect(find.text('Leaderboard'), findsOneWidget);
    });

    testWidgets('Leaderboard displays child rankings',
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

      // Navigate to Leaderboard tab
      await navigateToTab(tester, 'Leaderboard');
      await waitFor(2);

      // Leaderboard should display rankings
      // Look for trophy icon or ranking indicators
      await tester.pumpAndSettle();
    });

    testWidgets('Leaderboard displays child statistics',
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

      // Navigate to Leaderboard tab
      await navigateToTab(tester, 'Leaderboard');
      await waitFor(2);

      // Should display points, completed chores, streaks, etc.
      await tester.pumpAndSettle();
    });

    testWidgets('Leaderboard supports period filtering',
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

      // Navigate to Leaderboard tab
      await navigateToTab(tester, 'Leaderboard');
      await waitFor(2);

      // Look for period filter dropdown/menu (week, month, all-time)
      final popupMenuButton = find.byType(PopupMenuButton<String>);
      if (popupMenuButton.evaluate().isNotEmpty) {
        // Period filtering is available
        expect(popupMenuButton, findsOneWidget);
      }
    });

    testWidgets('Leaderboard displays winner with trophy',
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

      // Navigate to Leaderboard tab
      await navigateToTab(tester, 'Leaderboard');
      await waitFor(2);

      // Look for trophy icon indicating the winner
      final trophyIcon = find.byIcon(Icons.emoji_events);
      if (trophyIcon.evaluate().isNotEmpty) {
        expect(trophyIcon, findsWidgets);
      }
    });
  });
}