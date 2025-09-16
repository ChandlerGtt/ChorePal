import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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

  testWidgets('Login button exists and is tappable', (WidgetTester tester) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle(); // wait for all animations

    await Future.delayed(const Duration(seconds:2));



    // Find the Login button and tap it
    final loginButton = find.text('Login');
    expect(loginButton, findsOneWidget);

    await Future.delayed(const Duration(seconds: 2));

    await tester.tap(loginButton);
    await tester.pumpAndSettle(); // wait for any resulting animations

  });
}