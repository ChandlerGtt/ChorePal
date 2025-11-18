/// Mock data and test credentials for integration tests

class TestCredentials {
  static const String adultEmail = 'NewUser@example.com';
  static const String adultPassword = 'Password!1234';
  static const String adultName = 'NewUser';

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
  //824805//