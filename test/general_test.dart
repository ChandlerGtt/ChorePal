import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/adultLoginTest.dart' as login;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Tests', () {
    login.main();
  });
}
