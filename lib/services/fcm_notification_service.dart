import 'package:cloud_functions/cloud_functions.dart';

class FCMNotificationService {
  static final _sendNotification = FirebaseFunctions.instance.httpsCallable('sendNotification');

  /// Send an FCM push notification to a user
  /// Returns true if successful, false otherwise
  static Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final result = await _sendNotification.call({
        'userId': userId,
        'title': title,
        'body': body,
        if (data != null) 'data': data,
      });
      print('FCM notification sent successfully: $result');
      return true;
    } catch (e) {
      print('Error sending FCM notification: $e');
      print('Error details: ${e.toString()}');
      if (e is FirebaseFunctionsException) {
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
      }
      return false; // Don't rethrow, just return false
    }
  }
}

