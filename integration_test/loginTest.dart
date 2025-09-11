import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chore_pal/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Login button exists and is tappable', (WidgetTester tester) async {
    // Launch the app
    app.main();
    await tester.pumpAndSettle(); // wait for all animations

    // Find the Login button and tap it
    final loginButton = find.text('Login');
    expect(loginButton, findsOneWidget);

    await tester.tap(loginButton);
    await tester.pumpAndSettle(); // wait for any resulting animations
  });
}