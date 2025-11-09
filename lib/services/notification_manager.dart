import '../services/firestore_service.dart';
import 'notification_scheduler.dart';
import '../widgets/notification_helper.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FirestoreService _firestoreService = FirestoreService();
  final NotificationScheduler _scheduler = NotificationScheduler();

  // Initialize notifications for a child
  Future<void> initializeChildNotifications(
      String childId, String childName) async {
    try {
      await _scheduler.scheduleDailyReminders(childId, childName);
      await _scheduler.scheduleOverdueCheck(childId);
      await _scheduler.scheduleWeeklySummary(childId);
      await _scheduler.scheduleRewardCheck(childId);

      print('Notifications initialized for child: $childName');
    } catch (e) {
      print('Error initializing child notifications: $e');
    }
  }

  // Check and send daily reminders
  Future<void> checkDailyReminders(
      String childId, String childName, String familyId) async {
    try {
      final chores =
          await _firestoreService.getChoresForChild(childId, familyId);
      final today = DateTime.now();
      final pendingChores = chores
          .where((chore) =>
              !chore.isCompleted &&
              chore.deadline.isBefore(today.add(Duration(days: 1))))
          .toList();

      await NotificationHelper.showDailyReminder(
          childName, pendingChores.length);
    } catch (e) {
      print('Error checking daily reminders: $e');
    }
  }

  // Check and send overdue chore alerts
  Future<void> checkOverdueChores(
      String childId, String childName, String familyId) async {
    try {
      final chores =
          await _firestoreService.getChoresForChild(childId, familyId);
      final now = DateTime.now();

      final overdueChores = chores
          .where((chore) => !chore.isCompleted && chore.deadline.isBefore(now))
          .map((chore) => chore.title)
          .toList();

      if (overdueChores.isNotEmpty) {
        await NotificationHelper.showOverdueChoreAlert(
            childName, overdueChores);
      }
    } catch (e) {
      print('Error checking overdue chores: $e');
    }
  }

  // Check and send streak achievements
  Future<void> checkStreakAchievements(
      String childId, String childName, String familyId) async {
    try {
      final streakDays = await _calculateStreak(childId, familyId);

      if (streakDays > 0 && _isStreakMilestone(streakDays)) {
        await NotificationHelper.showStreakAchievement(childName, streakDays);
      }
    } catch (e) {
      print('Error checking streak achievements: $e');
    }
  }

  // Check and send weekly summary
  Future<void> checkWeeklySummary(
      String childId, String childName, String familyId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(Duration(days: 6));

      final chores =
          await _firestoreService.getChoresForChild(childId, familyId);
      final weeklyChores = chores
          .where((chore) =>
              chore.deadline.isAfter(weekStart) &&
              chore.deadline.isBefore(weekEnd))
          .toList();

      final completedChores =
          weeklyChores.where((chore) => chore.isCompleted).length;
      final totalChores = weeklyChores.length;
      final pointsEarned =
          await _calculateWeeklyPoints(childId, familyId, weekStart, weekEnd);

      await NotificationHelper.showWeeklySummary(
          childName, completedChores, totalChores, pointsEarned);
    } catch (e) {
      print('Error checking weekly summary: $e');
    }
  }

  // Check and send reward availability alerts
  Future<void> checkRewardAvailability(String childId, String childName) async {
    try {
      final currentPoints = await _firestoreService.getChildPoints(childId);
      // For now, we'll create a simple reward check
      // TODO: Implement proper reward system integration
      if (currentPoints >= 50) {
        await NotificationHelper.showRewardAvailable(
            childName, "Extra Screen Time", 50, currentPoints);
      }
    } catch (e) {
      print('Error checking reward availability: $e');
    }
  }

  // Check if streak is at risk (no chores completed today)
  Future<void> checkStreakAtRisk(
      String childId, String childName, String familyId) async {
    try {
      final streakDays = await _calculateStreak(childId, familyId);
      if (streakDays > 0) {
        final today = DateTime.now();
        final todayChores =
            await _firestoreService.getChoresForChild(childId, familyId);
        final completedToday = todayChores.any((chore) =>
            chore.isCompleted &&
            chore.completedAt != null &&
            _isSameDay(chore.completedAt!, today));

        if (!completedToday) {
          await NotificationHelper.showStreakAtRisk(childName, streakDays);
        }
      }
    } catch (e) {
      print('Error checking streak at risk: $e');
    }
  }

  // Helper method to calculate streak
  Future<int> _calculateStreak(String childId, String familyId) async {
    try {
      final chores =
          await _firestoreService.getChoresForChild(childId, familyId);
      final completedChores = chores
          .where((chore) => chore.isCompleted && chore.completedAt != null)
          .toList();

      if (completedChores.isEmpty) return 0;

      // Sort by completion date
      completedChores.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

      int streak = 0;
      DateTime currentDate = DateTime.now();

      for (final chore in completedChores) {
        if (_isSameDay(chore.completedAt!, currentDate) ||
            _isSameDay(
                chore.completedAt!, currentDate.subtract(Duration(days: 1)))) {
          streak++;
          currentDate = currentDate.subtract(Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  // Helper method to check if streak is a milestone
  bool _isStreakMilestone(int streakDays) {
    return streakDays == 3 ||
        streakDays == 7 ||
        streakDays == 14 ||
        streakDays == 30 ||
        streakDays == 60 ||
        streakDays == 100;
  }

  // Helper method to calculate weekly points
  Future<int> _calculateWeeklyPoints(String childId, String familyId,
      DateTime weekStart, DateTime weekEnd) async {
    try {
      final chores =
          await _firestoreService.getChoresForChild(childId, familyId);
      final weeklyChores = chores.where((chore) =>
          chore.isCompleted &&
          chore.completedAt != null &&
          chore.completedAt!.isAfter(weekStart) &&
          chore.completedAt!.isBefore(weekEnd));

      int totalPoints = 0;
      for (final chore in weeklyChores) {
        totalPoints += chore.pointValue;
      }
      return totalPoints;
    } catch (e) {
      print('Error calculating weekly points: $e');
      return 0;
    }
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Cancel all notifications for a child
  Future<void> cancelChildNotifications(String childId) async {
    await _scheduler.cancelChildNotifications(childId);
  }
}
