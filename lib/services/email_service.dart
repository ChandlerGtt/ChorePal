import 'package:cloud_functions/cloud_functions.dart';

class EmailService {
  static final _sendEmail =
  FirebaseFunctions.instance.httpsCallable('sendEmail');

  static Future<void> sendTestEmail(String to) async {
    final result = await _sendEmail.call({
      'to': to,
      'subject': 'Firebase Email Test',
      'message': 'It actually worked.'
    });
  }
}