// lib/widgets/chore_card.dart
import 'package:flutter/material.dart';
import '../models/chore.dart';

/// A card widget that displays a chore.
class ChoreCard extends StatelessWidget {
  final Chore chore;
  final bool isChild;
  final Function(String)? onToggleComplete;
  final Function(String, String, int)? onApprove;
  final Function(Chore)? onAssign;

  const ChoreCard({
    Key? key,
    required this.chore,
    this.isChild = false,
    this.onToggleComplete,
    this.onApprove,
    this.onAssign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (chore.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                chore.description,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Builds the header section of the card with title, status tags, and action button.
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chore.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  if (chore.priority == 'high') _buildPriorityTag(),
                  if (chore.isPendingApproval) _buildStatusTag(
                    'Awaiting Approval',
                    Colors.orange,
                  ),
                  if (chore.assignedTo.isNotEmpty && !chore.isPendingApproval && !chore.isCompleted)
                    _buildStatusTag(
                      'Assigned: ${chore.assignedTo.length}',
                      Colors.blue,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildActionButton(),
      ],
    );
  }

  /// Builds a tag showing the priority of the chore.
  Widget _buildPriorityTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        'High Priority',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
    );
  }

  /// Builds a status tag for the chore.
  Widget _buildStatusTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            text.contains('Awaiting') ? Icons.hourglass_top : Icons.person,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the footer section of the card with reward points and deadline.
  Widget _buildFooter() {
    final bool isPastDue = chore.deadline.isBefore(DateTime.now());
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (chore.pointValue > 0) 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.amber.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${chore.pointValue} points',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),
          
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isPastDue ? Colors.red.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPastDue ? Colors.red.shade200 : Colors.blue.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Due: ${chore.deadline.year}-${chore.deadline.month.toString().padLeft(2, '0')}-${chore.deadline.day.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${chore.deadline.hour.toString().padLeft(2, '0')}:${chore.deadline.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isPastDue ? Colors.red.shade700 : Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the appropriate action button based on chore status and user type.
  Widget _buildActionButton() {
    // If it's the child view and chore is not completed or pending approval
    if (isChild && !chore.isCompleted && !chore.isPendingApproval) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.check_circle_outline, color: Colors.green),
          tooltip: 'Mark as completed',
          onPressed: () => onToggleComplete?.call(chore.id),
        ),
      );
    }
    
    // If it's the parent view and chore is pending approval
    if (!isChild && chore.isPendingApproval && onApprove != null) {
      return ElevatedButton(
        onPressed: () => onApprove!(chore.id, chore.completedBy!, chore.pointValue),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Approve'),
      );
    }
    
    // If it's the parent view and chore is not completed or pending
    if (!isChild && !chore.isCompleted && !chore.isPendingApproval && onAssign != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.person_add, color: Colors.blue),
          tooltip: 'Assign to child',
          onPressed: () => onAssign!(chore),
        ),
      );
    }
    
    // For completed chores or pending chores in child view
    if (chore.isPendingApproval && isChild) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.hourglass_top, color: Colors.orange),
      );
    }
    
    if (chore.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.check_circle, color: Colors.green),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// Gets the appropriate border color based on chore status.
  Color _getBorderColor() {
    if (chore.isCompleted) {
      return Colors.green;
    }
    
    if (chore.isPendingApproval) {
      return Colors.orange;
    }
    
    return Colors.grey;
  }
}