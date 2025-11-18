// lib/screens/notification_test_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/notification_helper.dart';
import '../models/user_state.dart';
import '../utils/chorepal_colors.dart';

class NotificationTestScreen extends StatelessWidget {
  const NotificationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final userState = Provider.of<UserState>(context);
    final user = userState.currentUser;
    final isChild = user != null && !user.isParent;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: ChorePalColors.primaryGradient,
          ),
        ),
        title: const Text('Notification Tests'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? ChorePalColors.darkBackgroundGradient
              : ChorePalColors.backgroundGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 16),
            Text(
              'Test All Notification Types',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap buttons below to test each notification type',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? Colors.grey.shade300
                    : ChorePalColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Immediate Event Notifications
            _buildSectionHeader(context, 'Immediate Event Notifications', isDarkMode),
            const SizedBox(height: 12),
            
            _buildTestButton(
              context,
              'Chore Completed (Parent)',
              'Test notification when child completes chore',
              Icons.check_circle,
              Colors.green,
              () async {
                await NotificationHelper.showChoreCompletedByChildNotification(
                  'Test Child',
                  'Test Chore',
                );
                _showSuccess(context, 'Chore completed notification sent!');
              },
            ),
            
            _buildTestButton(
              context,
              'Chore Approved (Child)',
              'Test notification when parent approves chore',
              Icons.approval,
              Colors.blue,
              () async {
                await NotificationHelper.showChoreApprovedNotification(
                  null, // targetChildId - null for test (uses current user)
                  'Test Chore',
                  10,
                );
                _showSuccess(context, 'Chore approved notification sent!');
              },
            ),
            
            _buildTestButton(
              context,
              'New Chore Assigned (Child)',
              'Test notification when chore is assigned',
              Icons.assignment,
              Colors.orange,
              () async {
                await NotificationHelper.showNewChoreAssigned(
                  null, // targetChildId - null for test (uses current user)
                  'Test Chore Assignment',
                );
                _showSuccess(context, 'New chore assigned notification sent!');
              },
            ),
            
            _buildTestButton(
              context,
              'Chore Approval Needed (Parent)',
              'Test notification when approval is needed',
              Icons.pending_actions,
              Colors.amber,
              () async {
                await NotificationHelper.showChoreApprovalNeeded(
                  'Test Parent',
                  'Test Child',
                  'Test Chore',
                );
                _showSuccess(context, 'Approval needed notification sent!');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Essential Notifications (Child Only)
            if (isChild) ...[
              _buildSectionHeader(context, 'Child Notifications', isDarkMode),
              const SizedBox(height: 12),
              
              _buildTestButton(
                context,
                'Daily Reminder',
                'Test daily chore reminder',
                Icons.notifications_active,
                Colors.purple,
                () async {
                  await NotificationHelper.showDailyReminder('Test Child', 3);
                  _showSuccess(context, 'Daily reminder notification sent!');
                },
              ),
              
              _buildTestButton(
                context,
                'Overdue Chore Alert',
                'Test overdue chores notification',
                Icons.warning,
                Colors.red,
                () async {
                  await NotificationHelper.showOverdueChoreAlert(
                    'Test Child',
                    ['Chore 1', 'Chore 2', 'Chore 3'],
                  );
                  _showSuccess(context, 'Overdue alert notification sent!');
                },
              ),
              
              _buildTestButton(
                context,
                'Streak Achievement',
                'Test streak achievement notification',
                Icons.local_fire_department,
                Colors.orange,
                () async {
                  await NotificationHelper.showStreakAchievement('Test Child', 7);
                  _showSuccess(context, 'Streak achievement notification sent!');
                },
              ),
              
              _buildTestButton(
                context,
                'Weekly Summary',
                'Test weekly progress summary',
                Icons.bar_chart,
                Colors.teal,
                () async {
                  await NotificationHelper.showWeeklySummary(
                    'Test Child',
                    15,
                    20,
                    150,
                  );
                  _showSuccess(context, 'Weekly summary notification sent!');
                },
              ),
              
              _buildTestButton(
                context,
                'Reward Available',
                'Test reward availability alert',
                Icons.card_giftcard,
                Colors.pink,
                () async {
                  await NotificationHelper.showRewardAvailable(
                    'Test Child',
                    'Extra Screen Time',
                    50,
                    75,
                  );
                  _showSuccess(context, 'Reward available notification sent!');
                },
              ),
              
              _buildTestButton(
                context,
                'Streak at Risk',
                'Test streak at risk warning',
                Icons.trending_down,
                Colors.red,
                () async {
                  await NotificationHelper.showStreakAtRisk('Test Child', 5);
                  _showSuccess(context, 'Streak at risk notification sent!');
                },
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Simple Notifications
            _buildSectionHeader(context, 'Simple Notifications', isDarkMode),
            const SizedBox(height: 12),
            
            _buildTestButton(
              context,
              'Chore Completed',
              'Test simple chore completion',
              Icons.check_circle_outline,
              Colors.green,
              () async {
                await NotificationHelper.showChoreCompletedNotification('Test Chore');
                _showSuccess(context, 'Chore completed notification sent!');
              },
            ),
            
            _buildTestButton(
              context,
              'Reward Earned',
              'Test reward earned notification',
              Icons.emoji_events,
              Colors.amber,
              () async {
                await NotificationHelper.showRewardEarnedNotification('Test Reward');
                _showSuccess(context, 'Reward earned notification sent!');
              },
            ),
            
            _buildTestButton(
              context,
              'Milestone Reached',
              'Test milestone notification',
              Icons.stars,
              Colors.purple,
              () async {
                await NotificationHelper.showMilestoneNotification('100 Points Milestone!');
                _showSuccess(context, 'Milestone notification sent!');
              },
            ),
            
            const SizedBox(height: 24),
            
            // Notification Status
            _buildSectionHeader(context, 'Notification Status', isDarkMode),
            const SizedBox(height: 12),
            
            FutureBuilder<bool>(
              future: NotificationHelper.checkNotificationStatus(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? false;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEnabled ? Icons.notifications_active : Icons.notifications_off,
                        color: isEnabled ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEnabled
                              ? 'Notifications are enabled'
                              : 'Notifications are disabled',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white
                              : ChorePalColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.grey.shade300
                              : ChorePalColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : ChorePalColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

