import '../services/notification_service.dart';
import '../models/user.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();

  // Track current user context for notification routing
  static User? _currentUser;

  // Set the current user context
  static void setCurrentUser(User? user) {
    _currentUser = user;
  }

  // Get current user context
  static User? getCurrentUser() {
    return _currentUser;
  }

  // Show a simple test notification
  static Future<void> showTestNotification() async {
    await _notificationService.showNotification(
      id: 1,
      title: 'ChorePal',
      body: 'This is a test notification!',
    );
  }

  // Show chore completion notification
  static Future<void> showChoreCompletedNotification(String choreName) async {
    await _notificationService.showNotification(
      id: 2,
      title: 'Chore Completed! 🎉',
      body: 'Great job completing "$choreName"!',
    );
  }

  // Show reward earned notification
  static Future<void> showRewardEarnedNotification(String rewardName) async {
    await _notificationService.showNotification(
      id: 3,
      title: 'Reward Earned! 🏆',
      body: 'You earned "$rewardName"!',
    );
  }

  // Show milestone notification
  static Future<void> showMilestoneNotification(String milestone) async {
    await _notificationService.showNotification(
      id: 4,
      title: 'Milestone Reached! 🌟',
      body: 'Congratulations! $milestone',
    );
  }

  // Request permissions and show a test notification
  static Future<void> requestPermissionsAndTest() async {
    print('Requesting notification permissions...');
    final hasPermission = await _notificationService.requestPermissions();
    print('Permission granted: $hasPermission');

    if (hasPermission) {
      print('Showing test notification...');
      await showTestNotification();
    } else {
      print('Permission denied, cannot show test notification');
    }
  }

  // Check notification status
  static Future<bool> checkNotificationStatus() async {
    return await _notificationService.areNotificationsEnabled();
  }

  // Show notification when child completes a chore (for parent)
  static Future<void> showChoreCompletedByChildNotification(
      String childName, String choreName) async {
    // Only show this notification to parents
    if (_currentUser != null && _currentUser!.isParent) {
      await _notificationService.showNotification(
        id: 5,
        title: 'Chore Completed! 📋',
        body:
            '$childName completed "$choreName" and is waiting for your approval.',
      );
    } else {
      print(
          'Notification skipped: Child completed chore notification should only go to parents');
    }
  }

  // Show notification when parent approves a chore (for child)
  static Future<void> showChoreApprovedNotification(
      String choreName, int points) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      await _notificationService.showNotification(
        id: 6,
        title: 'Chore Approved! ✅',
        body:
            'Great job! "$choreName" was approved. You earned $points points!',
      );
    } else {
      print(
          'Notification skipped: Chore approved notification should only go to children');
    }
  }

  // ===== ESSENTIAL NOTIFICATIONS =====

  // Daily chore reminders
  static Future<void> showDailyReminder(
      String childName, int pendingCount) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      String body = pendingCount > 0
          ? 'You have $pendingCount chore${pendingCount > 1 ? 's' : ''} to complete today!'
          : 'Great job! All your chores are done for today! 🎉';

      await _notificationService.showNotification(
        id: 10,
        title: 'Daily Chore Check-in 📋',
        body: body,
      );
    }
  }

  // Overdue chore alerts
  static Future<void> showOverdueChoreAlert(
      String childName, List<String> overdueChores) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      String choreList = overdueChores.take(3).join(', ');
      if (overdueChores.length > 3) {
        choreList += ' and ${overdueChores.length - 3} more';
      }

      await _notificationService.showNotification(
        id: 11,
        title: 'Overdue Chores Alert ⚠️',
        body: 'You have overdue chores: $choreList',
      );
    }
  }

  // Streak achievements
  static Future<void> showStreakAchievement(
      String childName, int streakDays) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      String emoji = streakDays >= 30
          ? '🏆'
          : streakDays >= 14
              ? '🔥'
              : '⭐';
      String message = streakDays >= 30
          ? 'Incredible! $streakDays days in a row!'
          : streakDays >= 14
              ? 'Amazing! $streakDays days straight!'
              : 'Great job! $streakDays days in a row!';

      await _notificationService.showNotification(
        id: 12,
        title: 'Streak Achievement $emoji',
        body: message,
      );
    }
  }

  // Weekly progress summary
  static Future<void> showWeeklySummary(String childName, int completedChores,
      int totalChores, int pointsEarned) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      double percentage =
          totalChores > 0 ? (completedChores / totalChores * 100) : 0;
      String performance = percentage >= 90
          ? 'Outstanding!'
          : percentage >= 70
              ? 'Great job!'
              : 'Keep it up!';

      await _notificationService.showNotification(
        id: 13,
        title: 'Weekly Summary 📊',
        body:
            '$performance You completed $completedChores/$totalChores chores and earned $pointsEarned points!',
      );
    }
  }

  // Reward availability alerts
  static Future<void> showRewardAvailable(String childName, String rewardName,
      int pointsNeeded, int currentPoints) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      int pointsToGo = pointsNeeded - currentPoints;

      await _notificationService.showNotification(
        id: 14,
        title: 'Reward Available! 🎁',
        body: pointsToGo <= 0
            ? 'You can now afford "$rewardName"! Redeem it?'
            : 'You\'re $pointsToGo points away from "$rewardName"!',
      );
    }
  }

  // Family coordination notifications
  static Future<void> showNewChoreAssigned(
      String childName, String choreName) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      await _notificationService.showNotification(
        id: 15,
        title: 'New Chore Assigned 📝',
        body: 'You have a new chore: "$choreName"',
      );
    }
  }

  static Future<void> showChoreApprovalNeeded(
      String parentName, String childName, String choreName) async {
    // Only show this notification to parents
    if (_currentUser != null && _currentUser!.isParent) {
      await _notificationService.showNotification(
        id: 16,
        title: 'Approval Needed 👨‍👩‍👧‍👦',
        body:
            '$childName completed "$choreName" and is waiting for your approval.',
      );
    }
  }

  // Streak at risk notification
  static Future<void> showStreakAtRisk(String childName, int streakDays) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      await _notificationService.showNotification(
        id: 17,
        title: 'Streak at Risk! 🔥',
        body:
            'Your $streakDays-day streak is at risk! Complete a chore today to keep it going!',
      );
    }
  }
}
