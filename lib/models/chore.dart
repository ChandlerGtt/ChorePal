// lib/models/chore.dart
class Chore {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  bool isCompleted;
  bool isPendingApproval;
  final int pointValue;
  final String priority; // 'high', 'medium', 'low'
  final List<String> assignedTo; // List of child IDs assigned to this chore
  final String? completedBy; // Child ID who completed the chore
  final DateTime? completedAt; // When the chore was completed

  Chore({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
    this.isPendingApproval = false,
    required this.pointValue,
    this.priority = 'medium',
    this.assignedTo = const [],
    this.completedBy,
    this.completedAt,
  });

  // Create a Chore from Firestore data
  factory Chore.fromFirestore(String id, Map<String, dynamic> data) {
    return Chore(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: data['deadline'] != null 
          ? (data['deadline']).toDate()
          : DateTime.now().add(const Duration(days: 1)),
      isCompleted: data['isCompleted'] ?? false,
      isPendingApproval: data['isPendingApproval'] ?? false,
      pointValue: data['pointValue'] is int 
          ? data['pointValue'] 
          : int.tryParse(data['pointValue']?.toString() ?? '0') ?? 0,
      priority: data['priority'] ?? 'medium',
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      completedBy: data['completedBy'],
      completedAt: data['completedAt'] != null 
          ? (data['completedAt']).toDate()
          : null,
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'deadline': deadline,
      'isCompleted': isCompleted,
      'isPendingApproval': isPendingApproval,
      'pointValue': pointValue,
      'priority': priority,
      'assignedTo': assignedTo,
      'completedBy': completedBy,
      'completedAt': completedAt,
    };
  }

  // Create a copy with updated fields
  Chore copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? deadline,
    bool? isCompleted,
    bool? isPendingApproval,
    int? pointValue,
    String? priority,
    List<String>? assignedTo,
    String? completedBy,
    DateTime? completedAt,
  }) {
    return Chore(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      isPendingApproval: isPendingApproval ?? this.isPendingApproval,
      pointValue: pointValue ?? this.pointValue,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      completedBy: completedBy ?? this.completedBy,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}