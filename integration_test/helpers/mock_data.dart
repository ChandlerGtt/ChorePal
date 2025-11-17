/// Mock data and test credentials for integration tests

class TestCredentials {
  static const String adultEmail = 'john@example.com';
  static const String adultPassword = 'password!1234';
  static const String adultName = 'john';

  // Child credentials can be added when child login is implemented
  static const String childEmail = 'child@example.com';
  static const String childPassword = 'childpass123';
  static const String childName = 'childuser';
}

class TestData {
  // Add any other mock data needed for tests
  static const List<String> adultTabs = [
    'Chores',
    'Statistics',
    'Leaderboard',
    'Children',
    'Rewards',
  ];
}
