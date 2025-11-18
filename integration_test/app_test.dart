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
import 'features/authentication_test.dart' as authentication;
import 'features/chore_management_test.dart' as chore_management;
import 'features/reward_management_test.dart' as reward_management;
import 'features/settings_test.dart' as settings;
import 'features/leaderboard_test.dart' as leaderboard;
import 'features/statistics_test.dart' as statistics;
import 'features/child_dashboard_test.dart' as child_dashboard;
import 'features/history_test.dart' as history;
import 'features/children_management_test.dart' as children_management;
import 'features/notification_test.dart' as notification;
import 'e2e/full_user_flow_test.dart' as e2e;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Run all test suites

  // Authentication tests
  authentication.main();
  adult_login.main();
  child_login.main();

  // Navigation tests
  adult_tab.main();

  // Feature tests
  chore_management.main();
  reward_management.main();
  settings.main();
  leaderboard.main();
  statistics.main();
  child_dashboard.main();
  history.main();
  children_management.main();
  notification.main();
  adult_modules.main();
  child_modules.main();

  // End-to-end tests
  e2e.main();
}
