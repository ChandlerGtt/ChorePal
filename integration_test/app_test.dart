import 'package:integration_test/integration_test.dart';

/// Main integration test suite runner
///
/// This file serves as the entry point for running all integration tests.
/// Import test suites here to run them together.
///
/// To run these tests:
/// flutter test integration_test/app_test.dart

// Import all test suites
import 'auth/adult_login_test.dart' as adult_login;
import 'auth/child_login_test.dart' as child_login;
import 'features/adult_tab_test.dart' as adult_tab;
import 'features/adult_modules_test.dart' as adult_modules;
import 'features/child_modules_test.dart' as child_modules;
import 'e2e/full_user_flow_test.dart' as e2e;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Run all test suites
  adult_login.main();
  child_login.main();
  adult_tab.main();
  adult_modules.main();
  child_modules.main();
  e2e.main();
}
