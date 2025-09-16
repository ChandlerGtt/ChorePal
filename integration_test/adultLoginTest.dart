import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:chore_pal/main.dart' as app;

/*

notes for the following test:
I should be able to enter login information for the following person

name: john
email: john@example.com
password: password!1234

and just land on the interface

 */

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login functions for adult account and is tappable', (WidgetTester tester) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle(); // wait for all animations

    await Future.delayed(const Duration(seconds:2));

    //find email and type in email

    final emailLoginText = find.byWidgetPredicate((w){
      return w is TextField && w.decoration?.labelText=='Email';
    });

    await tester.enterText(emailLoginText, 'john@example.com');
    await tester.pumpAndSettle(); //<- this is in case for animations (not necessary as of now but just in case

    //find password and type in password

    final passwordLoginText = find.byWidgetPredicate((w){
      return w is TextField && w.decoration?.labelText=='Password';
    });

    await tester.enterText(passwordLoginText, 'password!1234');
    await tester.pumpAndSettle();


    FocusManager.instance.primaryFocus?.unfocus();

    // Find the Login button and tap it
    final loginButton = find.text('Login');
    expect(loginButton, findsOneWidget);
    await tester.pumpAndSettle(); //<- this is necessary due to load times

    await Future.delayed(const Duration(seconds: 2));

    await tester.tap(loginButton);
    await tester.pumpAndSettle(); // wait for any resulting animations

  });
}