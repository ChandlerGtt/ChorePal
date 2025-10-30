import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:chore_pal/main.dart' as app;
import '../moduleTesting/adultModules/adultLogin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('does creating chore cause a problem', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds:2));


    //the main way to find this is based off the fact inside our code we used a default icon
    //and just context swtich which one we need

    await login(tester, email:"john@example.com", password:"password!1234");
    await tester.pumpAndSettle();

    await Future.delayed(const Duration(seconds:2));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await Future.delayed(const Duration(seconds:2));

    final choreTitle = find.byWidgetPredicate((w){
      return w is TextField && w.decoration?.labelText=='Chore Title';
    });

    await tester.enterText(choreTitle, "Take Out Trash");
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    final choreDescription = find.byWidgetPredicate((w){
      return w is TextField && w.decoration?.labelText=='Description';
    });

    await tester.enterText(choreDescription, "just move the trash outside damn it");
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(seconds: 2));

    //change the toggle switches here

    final rewardpointsSwitch = find.descendant(of: find.text('Include Reward Points'), matching: find.byType(Switch));

    await tester.tap(rewardpointsSwitch);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    final highPrioritySwitch = find.descendant(of:find.text('High Priority'), matching: find.byType(Switch));

    await tester.tap(highPrioritySwitch);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 2));

    final createChore = find.text('Create Chore');

    await tester.ensureVisible(createChore);
    await tester.tap(createChore);
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds : 2));

  });
}
