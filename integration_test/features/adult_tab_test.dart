import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for adult tab navigation
///
/// Verifies that tab navigation works correctly for adult users

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Adult Tab Navigation Tests', () {
    testWidgets('Can navigate between all adult tabs without issues',
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

      // Test navigation to Statistics tab
      await navigateToTab(tester, 'Statistics');
      await waitFor(2);

      // Test navigation to Leaderboard tab
      await navigateToTab(tester, 'Leaderboard');
      await waitFor(2);

      // Test navigation to Children tab
      await navigateToTab(tester, 'Children');
      await waitFor(2);

      // Test navigation to Rewards tab
      await navigateToTab(tester, 'Rewards');
      await waitFor(2);

      // Test navigation back to Chores tab
      await navigateToTab(tester, 'Chores');
      await waitFor(2);

      // Verify we're on the Chores tab
      expect(find.text('Chores'), findsOneWidget);
    });
  });
}
