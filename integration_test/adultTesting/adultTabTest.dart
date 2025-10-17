import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;
import '../moduleTesting/adultModules/adultLogin.dart';
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

  testWidgets('checking if swapping between tab is an issue or presents any underlying issue', (WidgetTester tester) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle(); // wait for all animations

    await Future.delayed(const Duration(seconds : 2));

    await login(tester, email:"john@example.com", password: "password!1234");

    await Future.delayed(const Duration(seconds : 2));

    await tester.tap(find.text('Statistics'));

    await Future.delayed(const Duration(seconds: 2));

  });
}