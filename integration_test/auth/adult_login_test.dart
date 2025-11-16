import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for adult login functionality
///
/// Verifies that an adult user can successfully log in with valid credentials

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Adult Login Tests', () {
    testWidgets('Adult can login with valid credentials',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // Perform login
      await login(
        tester,
        email: TestCredentials.adultEmail,
        password: TestCredentials.adultPassword,
      );

      // Wait for login to complete
      await waitFor(2);

      // Verify successful login by checking for a tab that should be visible
      expect(find.text('Chores'), findsOneWidget);
    });
  });
}
