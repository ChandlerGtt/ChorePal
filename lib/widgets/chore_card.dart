// lib/widgets/chore_card.dart
import 'package:flutter/material.dart';
import '../models/chore.dart';

class ChoreCard extends StatelessWidget {
  final Chore chore;
  final bool isChild;
  final Function(String)? onToggleComplete;
  final Function(String, String, int)? onApprove;

  const ChoreCard({
    Key? key,
    required this.chore,
    this.isChild = false,
    this.onToggleComplete,
    this.onApprove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPriorityColor(chore.priority),
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
                      ),
                      Row(
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
                        ],
                      ),
                    ],
                  ),
                ),
                if (isChild && !chore.isCompleted)
                  Checkbox(
                    value: chore.isCompleted,
                    onChanged: (bool? value) {
                      if (onToggleComplete != null) {
                        onToggleComplete!(chore.id);
                      }
                    },
                  ),
                if (!isChild && chore.isCompleted && onApprove != null)
                  ElevatedButton(
                    onPressed: () => onApprove!(chore.id, "childId", int.parse(chore.reward)),
                    child: const Text('Approve'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(chore.description),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reward: ${chore.reward} points',
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