import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

Future<void> login(WidgetTester tester, {required String email, required String password}) async{
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

  await tester.tap(loginButton);
  await tester.pumpAndSettle();
}