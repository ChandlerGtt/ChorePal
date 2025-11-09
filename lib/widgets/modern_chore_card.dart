import 'package:flutter/material.dart';
import '../models/chore.dart';
import '../utils/chorepal_colors.dart';
import 'glassmorphism_card.dart';

/// Modern chore card with glassmorphism
class ModernChoreCard extends StatelessWidget {
  final Chore chore;
  final bool isChild;
  final Function(String)? onToggleComplete;
  final Function(String, String, int)? onApprove;
  final Function(Chore)? onAssign;

  const ModernChoreCard({
    Key? key,
    required this.chore,
    this.isChild = false,
    this.onToggleComplete,
    this.onApprove,
    this.onAssign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPastDue = chore.deadline.isBefore(DateTime.now());
    final isHighPriority = chore.priority == 'high';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GlassmorphismCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      backgroundColor: _getCardColor().withOpacity(0.15),
      border: Border.all(
        color: _getBorderColor(),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority indicator
              if (isHighPriority)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.priority_high,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'HIGH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              if (chore.isPendingApproval) ...[
                if (isHighPriority) const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hourglass_top,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Action button
              _buildActionButton(context),
            ],
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            chore.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : ChorePalColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          if (chore.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              chore.description,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade300 : ChorePalColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Footer
          Row(
            children: [
              if (chore.pointValue > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ChorePalColors.lemonYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: ChorePalColors.sunshineOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${chore.pointValue} pts',
                        style: TextStyle(
                          color: ChorePalColors.sunshineOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Deadline
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isPastDue
                      ? Colors.red.withOpacity(0.1)
                      : ChorePalColors.softBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: isPastDue
                          ? Colors.red.shade700
                          : ChorePalColors.skyBlue,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${chore.deadline.day}/${chore.deadline.month}',
                      style: TextStyle(
                        color: isPastDue
                            ? Colors.red.shade700
                            : ChorePalColors.skyBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCardColor() {
    if (chore.isCompleted) return ChorePalColors.grassGreen;
    if (chore.isPendingApproval) return ChorePalColors.sunshineOrange;
    if (chore.priority == 'high') return Colors.red.shade400;
    return ChorePalColors.skyBlue;
  }

  Color _getBorderColor() {
    if (chore.isCompleted) return ChorePalColors.grassGreen.withOpacity(0.5);
    if (chore.isPendingApproval) return ChorePalColors.sunshineOrange.withOpacity(0.5);
    if (chore.priority == 'high') return Colors.red.shade400.withOpacity(0.5);
    return ChorePalColors.skyBlue.withOpacity(0.5);
  }

  Widget _buildActionButton(BuildContext context) {
    if (isChild && !chore.isCompleted && !chore.isPendingApproval) {
      return Container(
        decoration: BoxDecoration(
          gradient: ChorePalColors.successGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ChorePalColors.grassGreen.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onToggleComplete?.call(chore.id),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    if (!isChild && chore.isPendingApproval && onApprove != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: ChorePalColors.successGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onApprove!(chore.id, chore.completedBy!, chore.pointValue),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.approval, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Approve',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!isChild && !chore.isCompleted && !chore.isPendingApproval && onAssign != null) {
      return Container(
        decoration: BoxDecoration(
          color: ChorePalColors.skyBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ChorePalColors.skyBlue.withOpacity(0.5),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onAssign!(chore),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.person_add,
                color: ChorePalColors.skyBlue,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    if (chore.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ChorePalColors.grassGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.check_circle,
          color: ChorePalColors.grassGreen,
          size: 20,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

