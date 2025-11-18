import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Callback for notification taps (for deep linking)
  Function(RemoteMessage)? onNotificationTap;

  // Initialize the notification service
  Future<void> initialize() async {
    try {
      // Create notification channel for Android 8.0+
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);

      // Create notification channel for Android 8.0+
      await _createNotificationChannel();

      // Initialize Firebase Messaging
      await _firebaseMessaging.requestPermission();
      final fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $fcmToken');

      // Store token in Firestore if user is logged in
      await _storeFcmTokenIfLoggedIn(fcmToken);

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up notification tap handlers
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_handleTokenRefresh);

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Get FCM token
  Future<String?> getFcmToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Create notification channel for Android 8.0+
  Future<void> _createNotificationChannel() async {
    const androidNotificationChannel = AndroidNotificationChannel(
      'chorepal_channel',
      'ChorePal Notifications',
      description: 'Notifications for ChorePal app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      // For Android 13+ (API 33+), we need POST_NOTIFICATIONS permission
      final status = await Permission.notification.request();

      if (status.isGranted) {
        print('Notification permissions granted');
        return true;
      } else {
        print('Notification permissions denied: ${status.toString()}');
        return false;
      }
    } catch (e) {
      print('Error requesting notification permissions: $e');
      return false;
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      print('Error checking notification status: $e');
      return false;
    }
  }

  // Show a simple notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      // Check if notifications are enabled
      final hasPermission = await areNotificationsEnabled();
      if (!hasPermission) {
        print('Notifications not enabled, requesting permission...');
        final granted = await requestPermissions();
        if (!granted) {
          print('Permission denied, cannot show notification');
          return;
        }
      }

      const androidDetails = AndroidNotificationDetails(
        'chorepal_channel',
        'ChorePal Notifications',
        channelDescription: 'Notifications for ChorePal app',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      print('Attempting to show notification: $title');
      await _notifications.show(id, title, body, notificationDetails);
      print('Notification shown successfully');
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Schedule a notification for later
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chorepal_channel',
      'ChorePal Notifications',
      channelDescription: 'Notifications for ChorePal app',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Handling a foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    await showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'ChorePal',
      body: message.notification?.body ?? '',
    );
  }

  // Handle notification tap (deep linking)
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    print('Notification data: ${message.data}');

    // Call the callback if set (for navigation)
    if (onNotificationTap != null) {
      onNotificationTap!(message);
    }
  }

  // Handle token refresh
  Future<void> _handleTokenRefresh(String newToken) async {
    print('FCM Token refreshed: $newToken');
    await _storeFcmTokenIfLoggedIn(newToken);
  }

  // Store FCM token in Firestore if user is logged in
  Future<void> _storeFcmTokenIfLoggedIn(String? token) async {
    if (token == null) return;

    try {
      // Get current user ID from FirestoreService
      // We'll need to pass userId or get it from auth
      // For now, we'll store it when we have the userId
      // This will be called from auth_service after login
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  // Public method to store FCM token (called from auth_service)
  Future<void> storeFcmTokenForUser(String userId) async {
    try {
      final token = await getFcmToken();
      if (token != null) {
        await _firestoreService.updateUser(userId, {
          'fcmToken': token,
          'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
        });
        print('FCM token stored for user: $userId');
      }
    } catch (e) {
      print('Error storing FCM token for user: $e');
    }
  }

  // Clear FCM token from Firestore
  Future<void> clearFcmTokenForUser(String userId) async {
    try {
      await _firestoreService.updateUser(userId, {
        'fcmToken': null,
      });
      print('FCM token cleared for user: $userId');
    } catch (e) {
      print('Error clearing FCM token: $e');
    }
  }
}
