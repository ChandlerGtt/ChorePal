import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

/// Common helper functions for integration tests

/// Performs login with the provided email and password
Future<void> login(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  // Find email field and enter email
  final emailLoginText = find.byWidgetPredicate((w) {
    return w is TextField && w.decoration?.labelText == 'Email';
  });

  await tester.enterText(emailLoginText, email);
  await tester.pumpAndSettle();

  // Find password field and enter password
  final passwordLoginText = find.byWidgetPredicate((w) {
    return w is TextField && w.decoration?.labelText == 'Password';
  });

  await tester.enterText(passwordLoginText, password);
  await tester.pumpAndSettle();

  // Dismiss keyboard
  FocusManager.instance.primaryFocus?.unfocus();

  // Find the Login button and tap it
  final loginButton = find.text('Login');
  expect(loginButton, findsOneWidget);
  await tester.pumpAndSettle();

  await tester.tap(loginButton);
  await tester.pumpAndSettle();
}

/// Waits for a specified duration (wrapper for Future.delayed)
Future<void> waitFor(int seconds) async {
  await Future.delayed(Duration(seconds: seconds));
}

/// Navigates to a tab by tapping on the tab name
Future<void> navigateToTab(WidgetTester tester, String tabName) async {
  final tabFinder = find.text(tabName);
  expect(tabFinder, findsOneWidget);
  await tester.tap(tabFinder);
  await tester.pumpAndSettle();
}

/// Launches the app and waits for it to settle
Future<void> launchApp(WidgetTester tester, Function appMain) async {
  appMain();
  await tester.pumpAndSettle();
  await waitFor(2);
}
