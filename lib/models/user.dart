// lib/models/user.dart

// Base User class - superclass for Parent and Child
class User {
  final String id;
  final String name;
  final String familyId;
  final int points;
  final DateTime createdAt;
  final bool isParent;
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool smsNotificationsEnabled;

  User({
    required this.id,
    required this.name,
    required this.familyId,
    this.points = 0,
    DateTime? createdAt,
    required this.isParent,
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.smsNotificationsEnabled = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a User from Firestore data
  factory User.fromFirestore(String id, Map<String, dynamic> data) {
    final bool isParent = data['isParent'] ?? false;
    
    if (isParent) {
      return Parent.fromFirestore(id, data);
    } else {
      return Child.fromFirestore(id, data);
    }
  }

  // Base toFirestore method
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'familyId': familyId,
      'points': points,
      'createdAt': createdAt,
      'isParent': isParent,
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'emailNotificationsEnabled': emailNotificationsEnabled,
      'smsNotificationsEnabled': smsNotificationsEnabled,
    };
  }
}

// Parent subclass
class Parent extends User {
  final String email;
  final String? phoneNumber;

  Parent({
    required String id,
    required String name,
    required String familyId,
    required this.email,
    this.phoneNumber,
    DateTime? createdAt,
    bool pushNotificationsEnabled = true,
    bool emailNotificationsEnabled = true,
    bool smsNotificationsEnabled = false,
  }) : super(
    id: id,
    name: name,
    familyId: familyId,
    createdAt: createdAt,
    isParent: true,
    pushNotificationsEnabled: pushNotificationsEnabled,
    emailNotificationsEnabled: emailNotificationsEnabled,
    smsNotificationsEnabled: smsNotificationsEnabled,
  );

  // Create a Parent from Firestore data
  factory Parent.fromFirestore(String id, Map<String, dynamic> data) {
    return Parent(
      id: id,
      name: data['name'] ?? '',
      familyId: data['familyId'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt']).toDate() 
          : DateTime.now(),
      pushNotificationsEnabled: data['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: data['emailNotificationsEnabled'] ?? true,
      smsNotificationsEnabled: data['smsNotificationsEnabled'] ?? false,
    );
  }

  // Override toFirestore to include parent-specific fields
  @override
  Map<String, dynamic> toFirestore() {
    final baseMap = super.toFirestore();
    return {
      ...baseMap,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }
}

// Child subclass
class Child extends User {
  final List<String> completedChores;
  final List<String> redeemedRewards;
  final String? phoneNumber;

  Child({
    required String id,
    required String name,
    required String familyId,
    int points = 0,
    this.completedChores = const [],
    this.redeemedRewards = const [],
    this.phoneNumber,
    DateTime? createdAt,
    bool pushNotificationsEnabled = true,
    bool emailNotificationsEnabled = true,
    bool smsNotificationsEnabled = false,
  }) : super(
    id: id,
    name: name,
    familyId: familyId,
    points: points,
    createdAt: createdAt,
    isParent: false,
    pushNotificationsEnabled: pushNotificationsEnabled,
    emailNotificationsEnabled: emailNotificationsEnabled,
    smsNotificationsEnabled: smsNotificationsEnabled,
  );

  // Create a Child from Firestore data
  factory Child.fromFirestore(String id, Map<String, dynamic> data) {
    return Child(
      id: id,
      name: data['name'] ?? '',
      familyId: data['familyId'] ?? '',
      points: data['points'] ?? 0,
      completedChores: List<String>.from(data['completedChores'] ?? []),
      redeemedRewards: List<String>.from(data['redeemedRewards'] ?? []),
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt']).toDate() 
          : DateTime.now(),
      pushNotificationsEnabled: data['pushNotificationsEnabled'] ?? true,
      emailNotificationsEnabled: data['emailNotificationsEnabled'] ?? true,
      smsNotificationsEnabled: data['smsNotificationsEnabled'] ?? false,
    );
  }

  // Override toFirestore to include child-specific fields
  @override
  Map<String, dynamic> toFirestore() {
    final baseMap = super.toFirestore();
    return {
      ...baseMap,
      'completedChores': completedChores,
      'redeemedRewards': redeemedRewards,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
    };
  }

  // Add a completed chore
  Child addCompletedChore(String choreId) {
    List<String> updatedCompletedChores = List.from(completedChores);
    updatedCompletedChores.add(choreId);
    
    return Child(
      id: id,
      name: name,
      familyId: familyId,
      points: points,
      completedChores: updatedCompletedChores,
      redeemedRewards: redeemedRewards,
      phoneNumber: phoneNumber,
      createdAt: createdAt,
      pushNotificationsEnabled: pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled,
      smsNotificationsEnabled: smsNotificationsEnabled,
    );
  }

  // Add a redeemed reward
  Child addRedeemedReward(String rewardId) {
    List<String> updatedRedeemedRewards = List.from(redeemedRewards);
    updatedRedeemedRewards.add(rewardId);
    
    return Child(
      id: id,
      name: name,
      familyId: familyId,
      points: points,
      completedChores: completedChores,
      redeemedRewards: updatedRedeemedRewards,
      phoneNumber: phoneNumber,
      createdAt: createdAt,
      pushNotificationsEnabled: pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled,
      smsNotificationsEnabled: smsNotificationsEnabled,
    );
  }

  // Update points
  Child updatePoints(int newPoints) {
    return Child(
      id: id,
      name: name,
      familyId: familyId,
      points: newPoints,
      completedChores: completedChores,
      redeemedRewards: redeemedRewards,
      phoneNumber: phoneNumber,
      createdAt: createdAt,
      pushNotificationsEnabled: pushNotificationsEnabled,
      emailNotificationsEnabled: emailNotificationsEnabled,
      smsNotificationsEnabled: smsNotificationsEnabled,
    );
  }
} 