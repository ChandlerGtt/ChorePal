import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/email_service.dart';
import '../services/sms_service.dart';
import '../services/fcm_notification_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
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

  // Try to load current user from Firestore if not set
  static Future<User?> _tryLoadCurrentUser() async {
    try {
      final authService = AuthService();
      final authUser = authService.currentUser;
      if (authUser != null) {
        // Check if this is a child user (anonymous auth with stored child ID)
        final prefs = await SharedPreferences.getInstance();
        final storedChildId = prefs.getString('child_user_id');
        final storedFamilyId = prefs.getString('child_family_id');

        String? actualUserId;
        
        if (storedChildId != null && storedFamilyId != null) {
          // This is a child user - use the stored child ID
          actualUserId = storedChildId;
        } else {
          // This is a parent user - use the auth UID directly
          actualUserId = authUser.uid;
        }

        final userDoc = await _firestoreService.users.doc(actualUserId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final user = User.fromFirestore(actualUserId, userData);
          _currentUser = user; // Update context
          return user;
        }
      }
    } catch (e) {
      print('Error trying to load current user: $e');
    }
    return null;
  }

  // Helper method to send multi-channel notifications
  static Future<void> _sendMultiChannelNotification({
    required String title,
    required String body,
    required User? user,
    String? emailSubject,
  }) async {
    // If user is null, try to get it from current context
    User? targetUser = user ?? _currentUser;
    
    // If still null, try to load from UserState via Firestore
    if (targetUser == null) {
      print('Warning: No user context available for notification. Attempting to load user...');
      try {
        // Try to get user from auth service
        final authService = AuthService();
        final authUser = authService.currentUser;
        if (authUser != null) {
          // Try to load user from Firestore
          final userDoc = await _firestoreService.users.doc(authUser.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            targetUser = User.fromFirestore(authUser.uid, userData);
            // Update current user context for future notifications
            _currentUser = targetUser;
          }
        }
      } catch (e) {
        print('Error loading user for notification: $e');
      }
    }
    
    if (targetUser == null) {
      print('Error: Cannot send notification - no user context available');
      return;
    }

    // Refresh user preferences from Firestore
    User? updatedUser;
    try {
      updatedUser = await _firestoreService.getUserById(targetUser.id);
    } catch (e) {
      print('Error fetching user preferences: $e');
      updatedUser = targetUser; // Fallback to current user
    }

    // Send FCM push notification if enabled
    if (updatedUser.pushNotificationsEnabled) {
      try {
        // Send FCM notification via Cloud Function (for cross-device delivery)
        final fcmSuccess = await FCMNotificationService.sendNotification(
          userId: updatedUser.id,
          title: title,
          body: body,
        );
        
        // Also show local notification as fallback/for current device
        // This ensures the notification appears even if FCM fails
        if (!fcmSuccess) {
          await _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: title,
            body: body,
          );
        }
      } catch (e) {
        print('Error sending push notification: $e');
        // Fallback to local notification
        try {
          await _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch % 100000,
            title: title,
            body: body,
          );
        } catch (localError) {
          print('Error showing local notification fallback: $localError');
        }
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
      }
      // Children don't have phone numbers

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        try {
          await SMSService.sendSMS(phoneNumber, '$title\n$body');
        } catch (e) {
          print('Error sending SMS: $e');
        }
      }
    }
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

  // Check notification status
  static Future<bool> checkNotificationStatus() async {
    return await _notificationService.areNotificationsEnabled();
  }

  // Show notification when child completes a chore (for parent)
  static Future<void> showChoreCompletedByChildNotification(
      String childName, String choreName) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to parents
    if (user != null && user.isParent) {
      String body =
          '$childName completed "$choreName" and is waiting for your approval.';

      await _sendMultiChannelNotification(
        title: 'Chore Completed! 📋',
        body: body,
        user: user,
      );
    } else {
      print(
          'Notification skipped: Child completed chore notification should only go to parents (current user: ${user?.name ?? "null"}, isParent: ${user?.isParent ?? false})');
    }
  }

  // Show notification when parent approves a chore (for child)
  /// Send notification to a specific child when their chore is approved
  /// [targetChildId] - The ID of the child who should receive the notification
  /// [choreName] - The name of the approved chore
  /// [points] - Points earned
  static Future<void> showChoreApprovedNotification(
      String? targetChildId, String choreName, int points) async {
    // If targetChildId is provided, send to that specific child
    if (targetChildId != null) {
      try {
        final targetUser = await _firestoreService.getUserById(targetChildId);
        if (targetUser != null && !targetUser.isParent) {
          String body =
              'Great job! "$choreName" was approved. You earned $points points!';
          await _sendMultiChannelNotification(
            title: 'Chore Approved! ✅',
            body: body,
            user: targetUser,
          );
          return;
        }
      } catch (e) {
        print('Error sending approval notification to child $targetChildId: $e');
      }
    }
    
    // Fallback: Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
      String body =
          'Great job! "$choreName" was approved. You earned $points points!';

      await _sendMultiChannelNotification(
        title: 'Chore Approved! ✅',
        body: body,
        user: user,
      );
    } else {
      print(
          'Notification skipped: Chore approved notification should only go to children (current user: ${user?.name ?? "null"}, isParent: ${user?.isParent ?? true})');
    }
  }

  // ===== ESSENTIAL NOTIFICATIONS =====

  // Daily chore reminders
  static Future<void> showDailyReminder(
      String childName, int pendingCount) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
      String body = pendingCount > 0
          ? 'You have $pendingCount chore${pendingCount > 1 ? 's' : ''} to complete today!'
          : 'Great job! All your chores are done for today! 🎉';

      await _sendMultiChannelNotification(
        title: 'Daily Chore Check-in 📋',
        body: body,
        user: user,
      );
    }
  }

  // Overdue chore alerts
  static Future<void> showOverdueChoreAlert(
      String childName, List<String> overdueChores) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
      String choreList = overdueChores.take(3).join(', ');
      if (overdueChores.length > 3) {
        choreList += ' and ${overdueChores.length - 3} more';
      }

      await _sendMultiChannelNotification(
        title: 'Overdue Chores Alert ⚠️',
        body: 'You have overdue chores: $choreList',
        user: user,
      );
    }
  }

  // Streak achievements
  static Future<void> showStreakAchievement(
      String childName, int streakDays) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
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
        user: user,
      );
    }
  }

  // Weekly progress summary
  static Future<void> showWeeklySummary(String childName, int completedChores,
      int totalChores, int pointsEarned) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
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
        user: user,
        emailSubject: 'ChorePal Weekly Summary',
      );
    }
  }

  // Reward availability alerts
  static Future<void> showRewardAvailable(String childName, String rewardName,
      int pointsNeeded, int currentPoints) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
      int pointsToGo = pointsNeeded - currentPoints;
      String body = pointsToGo <= 0
          ? 'You can now afford "$rewardName"! Redeem it?'
          : 'You\'re $pointsToGo points away from "$rewardName"!';

      await _sendMultiChannelNotification(
        title: 'Reward Available! 🎁',
        body: body,
        user: user,
      );
    }
  }

  // Family coordination notifications
  /// Send notification to a specific child when they are assigned a chore
  /// [targetChildId] - The ID of the child who should receive the notification
  /// [choreName] - The name of the chore assigned
  static Future<void> showNewChoreAssigned(
      String? targetChildId, String choreName) async {
    // If targetChildId is provided, send to that specific child
    if (targetChildId != null) {
      try {
        final targetUser = await _firestoreService.getUserById(targetChildId);
        if (targetUser != null && !targetUser.isParent) {
          await _sendMultiChannelNotification(
            title: 'New Chore Assigned 📝',
            body: 'You have a new chore: "$choreName"',
            user: targetUser,
          );
          return;
        }
      } catch (e) {
        print('Error sending notification to child $targetChildId: $e');
      }
    }
    
    // Fallback: Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
      await _sendMultiChannelNotification(
        title: 'New Chore Assigned 📝',
        body: 'You have a new chore: "$choreName"',
        user: user,
      );
    }
  }

  static Future<void> showChoreApprovalNeeded(
      String parentName, String childName, String choreName) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to parents
    if (user != null && user.isParent) {
      String body =
          '$childName completed "$choreName" and is waiting for your approval.';

      await _sendMultiChannelNotification(
        title: 'Approval Needed 👨‍👩‍👧‍👦',
        body: body,
        user: user,
      );
    }
  }

  // Streak at risk notification
  static Future<void> showStreakAtRisk(String childName, int streakDays) async {
    // Get current user (will try to load if null)
    final user = _currentUser ?? await _tryLoadCurrentUser();
    
    // Only show this notification to children
    if (user != null && !user.isParent) {
      String body =
          'Your $streakDays-day streak is at risk! Complete a chore today to keep it going!';

      await _sendMultiChannelNotification(
        title: 'Streak at Risk! 🔥',
        body: body,
        user: user,
      );
    }
  }
}
