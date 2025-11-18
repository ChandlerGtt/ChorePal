import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  
  // Initialize local notifications to show the message
  final FlutterLocalNotificationsPlugin notifications = 
      FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await notifications.initialize(initSettings);
  
  // Create notification channel for Android
  const androidNotificationChannel = AndroidNotificationChannel(
    'chorepal_channel',
    'ChorePal Notifications',
    description: 'Notifications for ChorePal app',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );
  
  await notifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidNotificationChannel);
  
  // Show notification
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
  
  await notifications.show(
    message.hashCode,
    message.notification?.title ?? 'ChorePal',
    message.notification?.body ?? '',
    notificationDetails,
  );
}

