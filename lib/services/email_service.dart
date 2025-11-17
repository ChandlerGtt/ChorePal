import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  static final _sendEmail = FirebaseFunctions.instance.httpsCallable('email');

  /// Send an email message
  /// Returns true if successful, false otherwise
  static Future<bool> sendEmail(
      String to, String subject, String message) async {
    try {
      final result = await _sendEmail.call({
        'to': to,
        'subject': subject,
        'message': message,
      });
      print('Email sent successfully: $result');
      return true;
    } catch (e) {
      print('Error sending email: $e');
      print('Error details: ${e.toString()}');
      if (e is FirebaseFunctionsException) {
        print('Code: ${e.code}');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
      }
      rethrow; // Re-throw so we can see the actual error
    }
  }
}
