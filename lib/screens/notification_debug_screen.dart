import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../widgets/notification_helper.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  final NotificationService _notificationService = NotificationService();
  String _debugInfo = 'Initializing...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Running diagnostics...\n';
    });

    String info = '';

    try {
      // 1. Check if notification service is initialized
      info += '1. Notification Service Status:\n';
      info += '   ✅ Service instance created\n';

      // 2. Check permissions
      info += '\n2. Permission Check:\n';
      final hasPermission =
          await _notificationService.areNotificationsEnabled();
      info += hasPermission
          ? '   ✅ Notifications enabled\n'
          : '   ❌ Notifications disabled - requesting permission...\n';

      if (!hasPermission) {
        final granted = await _notificationService.requestPermissions();
        info += granted
            ? '   ✅ Permission granted\n'
            : '   ❌ Permission denied by user\n';
      }

      // 3. Test basic notification
      info += '\n3. Basic Notification Test:\n';
      try {
        await _notificationService.showNotification(
          id: 999,
          title: 'Debug Test',
          body: 'This is a test notification from ChorePal',
        );
        info += '   ✅ Test notification sent successfully\n';
      } catch (e) {
        info += '   ❌ Test notification failed: $e\n';
      }

      // 4. Test notification helper
      info += '\n4. Notification Helper Test:\n';
      try {
        await NotificationHelper.showTestNotification();
        info += '   ✅ NotificationHelper working\n';
      } catch (e) {
        info += '   ❌ NotificationHelper failed: $e\n';
      }

      // 5. Device information
      info += '\n5. Device Information:\n';
      info += '   Platform: ${Theme.of(context).platform.name}\n';
      info += '   Debug mode: ${kDebugMode}\n';

      // 6. Recommendations
      info += '\n6. Troubleshooting Recommendations:\n';
      if (!hasPermission) {
        info +=
            '   • Go to device Settings > Apps > ChorePal > Notifications\n';
        info += '   • Enable all notification types\n';
        info += '   • Check "Allow notifications" is ON\n';
      }
      info += '   • Disable battery optimization for ChorePal\n';
      info += '   • Turn off Do Not Disturb mode\n';
      info += '   • Check notification channels in device settings\n';
    } catch (e) {
      info += '\n❌ Diagnostic Error: $e\n';
    }

    setState(() {
      _debugInfo = info;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification System Diagnostics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _runDiagnostics,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Run Diagnostics'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await NotificationHelper.showTestNotification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Test notification sent!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Send Test'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
