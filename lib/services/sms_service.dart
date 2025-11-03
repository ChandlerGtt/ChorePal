import 'package:cloud_functions/cloud_functions.dart';

class SMSService {
  static final _sendSMS = FirebaseFunctions.instance.httpsCallable('sms');

  /// Send an SMS message to a phone number
  /// Phone number must be in E.164 format (e.g., +15551234567)
  static Future<bool> sendSMS(String to, String message) async {
    try {
      final result = await _sendSMS.call({
        'to': to,
        'message': message,
      });
      print('SMS sent successfully: $result');
      return true;
    } catch (e) {
      print('Error sending SMS: $e');
      print('Error details: ${e.toString()}');
      if (e is FirebaseFunctionsException) {
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
      }
      rethrow; // Re-throw so we can see the actual error
    }
  }

  /// Send a test SMS to the hardcoded test number
  static Future<bool> sendTestSMS() async {
    try {
      const testNumber = '+12148433202';
      const testMessage = 'Test SMS from ChorePal - This is a test message!';
      return await sendSMS(testNumber, testMessage);
    } catch (e) {
      print('sendTestSMS error: $e');
      rethrow; // Re-throw so dashboard can show the error
    }
  }
}
