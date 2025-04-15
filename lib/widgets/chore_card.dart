// lib/widgets/chore_card.dart
import 'package:flutter/material.dart';
import '../models/chore.dart';

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
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chore.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Wrap(
                        spacing: 8.0,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(chore.priority).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getPriorityText(chore.priority),
                              style: TextStyle(
                                color: _getPriorityColor(chore.priority),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (chore.isPendingApproval) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Awaiting Approval',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (chore.assignedTo.isNotEmpty && !chore.isPendingApproval && !chore.isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Assigned: ${chore.assignedTo.length}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionButton(),
              ],
            ),
            const SizedBox(height: 8),
            Text(chore.description),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reward: ${chore.pointValue} points',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Due: ${chore.deadline.toString().split(' ')[0]}',
                  style: TextStyle(
                    color: chore.deadline.isBefore(DateTime.now())
                        ? Colors.red
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    // If it's the child view and chore is not completed or pending approval
    if (isChild && !chore.isCompleted && !chore.isPendingApproval) {
      return Checkbox(
        value: false,
        onChanged: (bool? value) {
          if (onToggleComplete != null) {
            onToggleComplete!(chore.id);
          }
        },
      );
    }
    
    // If it's the parent view and chore is pending approval
    if (!isChild && chore.isPendingApproval && onApprove != null) {
      return ElevatedButton(
        onPressed: () => onApprove!(chore.id, chore.completedBy!, chore.pointValue),
        child: const Text('Approve'),
      );
    }
    
    // If it's the parent view and chore is not completed or pending
    if (!isChild && !chore.isCompleted && !chore.isPendingApproval && onAssign != null) {
      return IconButton(
        icon: const Icon(Icons.person_add),
        tooltip: 'Assign to child',
        onPressed: () => onAssign!(chore),
      );
    }
    
    // For completed chores or pending chores in child view
    if (chore.isPendingApproval && isChild) {
      return const Icon(Icons.hourglass_top, color: Colors.orange);
    }
    
    if (chore.isCompleted) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    return const SizedBox.shrink();
  }

  Color _getBorderColor() {
    if (chore.isCompleted) {
      return Colors.green;
    }
    
    if (chore.isPendingApproval) {
      return Colors.orange;
    }
    
    return _getPriorityColor(chore.priority);
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'High Priority';
      case 'medium':
        return 'Medium Priority';
      case 'low':
        return 'Low Priority';
      default:
        return 'Medium Priority';
    }
  }
}