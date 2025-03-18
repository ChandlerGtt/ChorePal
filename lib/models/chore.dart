// lib/models/chore.dart
class Chore {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  bool isCompleted;
  final String reward;
  final String priority; // 'high', 'medium', 'low'

  Chore({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
    required this.reward,
    this.priority = 'medium',
  });
}