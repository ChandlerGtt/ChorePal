import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// End-to-end test suite for complete user workflows
///
/// Tests realistic scenarios that users would perform

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E: Full User Flow Tests', () {
    testWidgets('Complete adult workflow: login and navigate all features',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Step 1: Login as adult
      await login(
        tester,
        email: TestCredentials.adultEmail,
        password: TestCredentials.adultPassword,
      );
      await waitFor(2);

      // Verify successful login
      expect(find.text('Chores'), findsOneWidget);

      // Step 2: Navigate through all tabs to verify accessibility
      for (final tab in TestData.adultTabs) {
        if (tab != 'Chores') {
          // Skip Chores as we're already there
          await navigateToTab(tester, tab);
          await waitFor(1);
          expect(find.text(tab), findsOneWidget);
        }
      }

      // Step 3: Return to Chores tab
      await navigateToTab(tester, 'Chores');
      await waitFor(1);

      // TODO: Add more comprehensive workflow steps
      // - Create a chore
      // - Assign to a child
      // - Mark as complete
      // - View statistics
      // - etc.
    });

    testWidgets('Complete child workflow: login and complete assigned chores',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // TODO: Implement child workflow
      // - Login as child
      // - View assigned chores
      // - Complete a chore
      // - View rewards/progress
    }, skip: true); // Skip until child functionality is implemented
  });
}
