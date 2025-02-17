import 'package:flutter/material.dart';
import '../models/chore.dart';

class ChoreCard extends StatelessWidget {
  final Chore chore;
  final bool isChild;

  const ChoreCard({
    Key? key,
    required this.chore,
    this.isChild = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  chore.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (isChild)
                  Checkbox(
                    value: chore.isCompleted,
                    onChanged: (bool? value) {
                      // Implement chore completion logic
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(chore.description),
            const SizedBox(height: 8),
            Text('Reward: ${chore.reward}'),
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
      ),
    );
  }
}