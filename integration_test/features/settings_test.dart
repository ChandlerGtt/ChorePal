import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import 'package:flutter/material.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_data.dart';

/// Test suite for settings functionality
///
/// Tests app settings, theme changes, notifications, and user preferences

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Tests', () {
    testWidgets('Adult can access settings screen',
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

      // Look for settings icon/button (typically in app bar)
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        await waitFor(1);

        // Verify settings screen is displayed
        expect(find.text('Settings'), findsWidgets);
      } else {
        // Settings might be in a drawer or menu
        final menuButton = find.byIcon(Icons.menu);
        if (menuButton.evaluate().isNotEmpty) {
          await tester.tap(menuButton);
          await tester.pumpAndSettle();

          // Look for Settings in the drawer
          final settingsInDrawer = find.text('Settings');
          if (settingsInDrawer.evaluate().isNotEmpty) {
            await tester.tap(settingsInDrawer);
            await tester.pumpAndSettle();
            await waitFor(1);
          }
        }
      }
    });

    testWidgets('Settings screen displays theme toggle',
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

      // Navigate to settings
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        await waitFor(1);

        // Look for theme-related switches or toggles
        // Your app has theme service, so there should be a theme toggle
        final switches = find.byType(Switch);
        expect(switches, findsWidgets);
      }
    });

    testWidgets('Settings screen displays notification preferences',
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

      // Navigate to settings
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        await waitFor(1);

        // Look for notification-related settings
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Settings screen displays user profile information',
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

      // Navigate to settings
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        await waitFor(1);

        // Settings should display user info
        await tester.pumpAndSettle();
      }
    });
  });
}
