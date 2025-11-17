import 'package:flutter/material.dart';
import '../utils/chorepal_colors.dart';

/// Professional empty state widget
class ProfessionalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final Color? backgroundColor;

  const ProfessionalEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? ChorePalColors.skyBlue;
    final effectiveBackgroundColor =
        backgroundColor ?? ChorePalColors.softBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: effectiveIconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 56,
                        color: effectiveIconColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: ChorePalColors.textPrimary,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: ChorePalColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Professional loading indicator
class ProfessionalLoadingIndicator extends StatelessWidget {
  final String? message;

  const ProfessionalLoadingIndicator({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ChorePalColors.skyBlue),
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            Text(
              message!,
              style: TextStyle(
                fontSize: 15,
                color: ChorePalColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
