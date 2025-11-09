import 'notification_service.dart';

class NotificationScheduler {
  static final NotificationScheduler _instance =
      NotificationScheduler._internal();
  factory NotificationScheduler() => _instance;
  NotificationScheduler._internal();

  final NotificationService _notificationService = NotificationService();

  // Schedule daily chore reminders
  Future<void> scheduleDailyReminders(String childId, String childName) async {
    try {
      // Morning reminder at 8 AM
      await _scheduleRecurringNotification(
        id: 100 + childId.hashCode,
        title: 'Good morning, $childName! 🌅',
        body: 'Time to check your chores for today!',
        hour: 8,
        minute: 0,
      );

      // Afternoon reminder at 3 PM
      await _scheduleRecurringNotification(
        id: 101 + childId.hashCode,
        title: 'Afternoon check-in 📋',
        body: 'How are your chores coming along?',
        hour: 15,
        minute: 0,
      );

      // Evening reminder at 7 PM
      await _scheduleRecurringNotification(
        id: 102 + childId.hashCode,
        title: 'Evening reminder 🌙',
        body: 'Don\'t forget to complete your chores before bedtime!',
        hour: 19,
        minute: 0,
      );

      print('Daily reminders scheduled for $childName');
    } catch (e) {
      print('Error scheduling daily reminders: $e');
    }
  }

  // Schedule overdue chore check (runs every 6 hours)
  Future<void> scheduleOverdueCheck(String childId) async {
    try {
      await _scheduleRecurringNotification(
        id: 200 + childId.hashCode,
        title: 'Overdue Chore Check',
        body: 'Checking for overdue chores...',
        hour: 12,
        minute: 0,
        interval: Duration(hours: 6),
      );
    } catch (e) {
      print('Error scheduling overdue check: $e');
    }
  }

  // Schedule weekly summary (Sundays at 6 PM)
  Future<void> scheduleWeeklySummary(String childId) async {
    try {
      await _scheduleWeeklyNotification(
        id: 300 + childId.hashCode,
        title: 'Weekly Summary 📊',
        body: 'Your weekly chore progress is ready!',
        weekday: DateTime.sunday,
        hour: 18,
        minute: 0,
      );
    } catch (e) {
      print('Error scheduling weekly summary: $e');
    }
  }

  // Schedule reward availability check (daily at 9 AM)
  Future<void> scheduleRewardCheck(String childId) async {
    try {
      await _scheduleRecurringNotification(
        id: 400 + childId.hashCode,
        title: 'Reward Check',
        body: 'Checking available rewards...',
        hour: 9,
        minute: 0,
      );
    } catch (e) {
      print('Error scheduling reward check: $e');
    }
  }

  // Helper method for recurring notifications
  Future<void> _scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    Duration? interval,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    await _notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  // Helper method for weekly notifications
  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledDate = _getNextWeekday(now, weekday, hour, minute);

    await _notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  // Get next occurrence of a specific weekday
  DateTime _getNextWeekday(DateTime now, int weekday, int hour, int minute) {
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Find the next occurrence of the weekday
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel all scheduled notifications for a child
  Future<void> cancelChildNotifications(String childId) async {
    try {
      final childHash = childId.hashCode;
      await _notificationService.cancelNotification(100 + childHash);
      await _notificationService.cancelNotification(101 + childHash);
      await _notificationService.cancelNotification(102 + childHash);
      await _notificationService.cancelNotification(200 + childHash);
      await _notificationService.cancelNotification(300 + childHash);
      await _notificationService.cancelNotification(400 + childHash);

      print('Cancelled all notifications for child: $childId');
    } catch (e) {
      print('Error cancelling child notifications: $e');
    }
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllScheduledNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      print('Cancelled all scheduled notifications');
    } catch (e) {
      print('Error cancelling all notifications: $e');
    }
  }
}
