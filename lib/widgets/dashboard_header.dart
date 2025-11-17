// lib/widgets/dashboard_header.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../utils/chorepal_colors.dart';

/// Dashboard header widget that flows seamlessly into the app screen
/// Displays user name and profile icon with selection capability
class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  final User? user;
  final List<Widget>? actions;
  final VoidCallback? onProfileIconTap;

  const DashboardHeader({
    super.key,
    required this.user,
    this.actions,
    this.onProfileIconTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDarkMode
            ? ChorePalColors.darkBlueGradient
            : ChorePalColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color:
                (isDarkMode ? ChorePalColors.darkBlue : ChorePalColors.skyBlue)
                    .withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // App title/logo area
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ChorePal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Actions (menu, settings, etc.)
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
