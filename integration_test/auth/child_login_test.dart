import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import '../helpers/test_helpers.dart';
// import '../helpers/mock_data.dart'; // Uncomment when implementing child login

/// Test suite for child login functionality
///
/// Verifies that a child user can successfully log in with valid credentials

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Child Login Tests', () {
    testWidgets('Child can login with valid credentials',
        (WidgetTester tester) async {
      // Launch the app
      await launchApp(tester, app.main);

      // TODO: Implement child login test
      // await login(
      //   tester,
      //   email: TestCredentials.childEmail,
      //   password: TestCredentials.childPassword,
      // );

      // await waitFor(2);

      // Verify successful login
      // Add assertions for child dashboard elements
    }, skip: true); // Skip until child login is implemented
  });
}
