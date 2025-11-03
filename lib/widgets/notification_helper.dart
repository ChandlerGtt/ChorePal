import '../services/notification_service.dart';
import '../services/email_service.dart';
import '../services/sms_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();
  static final FirestoreService _firestoreService = FirestoreService();

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

  // Helper method to send multi-channel notifications
  static Future<void> _sendMultiChannelNotification({
    required String title,
    required String body,
    required User? user,
    String? emailSubject,
  }) async {
    if (user == null) return;

    // Refresh user preferences from Firestore
    User? updatedUser;
    try {
      updatedUser = await _firestoreService.getUserById(user.id);
    } catch (e) {
      print('Error fetching user preferences: $e');
      updatedUser = user; // Fallback to current user
    }

    // Send push notification if enabled
    if (updatedUser.pushNotificationsEnabled) {
      try {
        await _notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          title: title,
          body: body,
        );
      } catch (e) {
        print('Error sending push notification: $e');
      }
    }

    // Send email if enabled and user is Parent with email
    if (updatedUser.emailNotificationsEnabled && updatedUser is Parent) {
      try {
        final emailTitle = emailSubject ?? title;
        await EmailService.sendEmail(
          updatedUser.email,
          emailTitle,
          body,
        );
      } catch (e) {
        print('Error sending email: $e');
      }
    }

    // Send SMS if enabled and phone number exists
    if (updatedUser.smsNotificationsEnabled) {
      String? phoneNumber;
      if (updatedUser is Parent && updatedUser.phoneNumber != null) {
        phoneNumber = updatedUser.phoneNumber;
      } else if (updatedUser is Child && updatedUser.phoneNumber != null) {
        phoneNumber = updatedUser.phoneNumber;
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        try {
          await SMSService.sendSMS(phoneNumber, '$title\n$body');
        } catch (e) {
          print('Error sending SMS: $e');
        }
      }
    }
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
      String body =
          '$childName completed "$choreName" and is waiting for your approval.';

      await _sendMultiChannelNotification(
        title: 'Chore Completed! 📋',
        body: body,
        user: _currentUser,
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
      String body =
          'Great job! "$choreName" was approved. You earned $points points!';

      await _sendMultiChannelNotification(
        title: 'Chore Approved! ✅',
        body: body,
        user: _currentUser,
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

      await _sendMultiChannelNotification(
        title: 'Daily Chore Check-in 📋',
        body: body,
        user: _currentUser,
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

      await _sendMultiChannelNotification(
        title: 'Overdue Chores Alert ⚠️',
        body: 'You have overdue chores: $choreList',
        user: _currentUser,
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

      await _sendMultiChannelNotification(
        title: 'Streak Achievement $emoji',
        body: message,
        user: _currentUser,
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

      String body =
          '$performance You completed $completedChores/$totalChores chores and earned $pointsEarned points!';

      await _sendMultiChannelNotification(
        title: 'Weekly Summary 📊',
        body: body,
        user: _currentUser,
        emailSubject: 'ChorePal Weekly Summary',
      );
    }
  }

  // Reward availability alerts
  static Future<void> showRewardAvailable(String childName, String rewardName,
      int pointsNeeded, int currentPoints) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      int pointsToGo = pointsNeeded - currentPoints;
      String body = pointsToGo <= 0
          ? 'You can now afford "$rewardName"! Redeem it?'
          : 'You\'re $pointsToGo points away from "$rewardName"!';

      await _sendMultiChannelNotification(
        title: 'Reward Available! 🎁',
        body: body,
        user: _currentUser,
      );
    }
  }

  // Family coordination notifications
  static Future<void> showNewChoreAssigned(
      String childName, String choreName) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      await _sendMultiChannelNotification(
        title: 'New Chore Assigned 📝',
        body: 'You have a new chore: "$choreName"',
        user: _currentUser,
      );
    }
  }

  static Future<void> showChoreApprovalNeeded(
      String parentName, String childName, String choreName) async {
    // Only show this notification to parents
    if (_currentUser != null && _currentUser!.isParent) {
      String body =
          '$childName completed "$choreName" and is waiting for your approval.';

      await _sendMultiChannelNotification(
        title: 'Approval Needed 👨‍👩‍👧‍👦',
        body: body,
        user: _currentUser,
      );
    }
  }

  // Streak at risk notification
  static Future<void> showStreakAtRisk(String childName, int streakDays) async {
    // Only show this notification to children
    if (_currentUser != null && !_currentUser!.isParent) {
      String body =
          'Your $streakDays-day streak is at risk! Complete a chore today to keep it going!';

      await _sendMultiChannelNotification(
        title: 'Streak at Risk! 🔥',
        body: body,
        user: _currentUser,
      );
    }
  }
}
