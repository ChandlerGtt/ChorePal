// lib/models/family.dart
class Family {
  final String id;
  final String name;
  final List<String> parentIds;
  final List<String> childrenIds;
  final String familyCode;
  final DateTime createdAt;

  Family({
    required this.id,
    required this.name,
    required this.parentIds,
    required this.childrenIds,
    required this.familyCode,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a Family from Firestore data
  factory Family.fromFirestore(String id, Map<String, dynamic> data) {
    return Family(
      id: id,
      name: data['name'] ?? 'Family',
      parentIds: List<String>.from(data['parentIds'] ?? []),
      childrenIds: List<String>.from(data['childrenIds'] ?? []),
      familyCode: data['familyCode'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt']).toDate() 
          : DateTime.now(),
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'parentIds': parentIds,
      'childrenIds': childrenIds,
      'familyCode': familyCode,
      'createdAt': createdAt,
    };
  }

  // Create a copy with updated fields
  Family copyWith({
    String? id,
    String? name,
    List<String>? parentIds,
    List<String>? childrenIds,
    String? familyCode,
    DateTime? createdAt,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      parentIds: parentIds ?? this.parentIds,
      childrenIds: childrenIds ?? this.childrenIds,
      familyCode: familyCode ?? this.familyCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Add a child to the family
  Family addChild(String childId) {
    if (childrenIds.contains(childId)) {
      return this;
    }
    
    List<String> updatedChildrenIds = List.from(childrenIds);
    updatedChildrenIds.add(childId);
    
    return copyWith(
      childrenIds: updatedChildrenIds,
    );
  }

  // Add a parent to the family
  Family addParent(String parentId) {
    if (parentIds.contains(parentId)) {
      return this;
    }
    
    List<String> updatedParentIds = List.from(parentIds);
    updatedParentIds.add(parentId);
    
    return copyWith(
      parentIds: updatedParentIds,
    );
  }

  // Remove a child from the family
  Family removeChild(String childId) {
    if (!childrenIds.contains(childId)) {
      return this;
    }
    
    List<String> updatedChildrenIds = List.from(childrenIds);
    updatedChildrenIds.remove(childId);
    
    return copyWith(
      childrenIds: updatedChildrenIds,
    );
  }

  // Remove a parent from the family
  Family removeParent(String parentId) {
    if (!parentIds.contains(parentId) || parentIds.length <= 1) {
      // Don't remove the last parent
      return this;
    }
    
    List<String> updatedParentIds = List.from(parentIds);
    updatedParentIds.remove(parentId);
    
    return copyWith(
      parentIds: updatedParentIds,
    );
  }
} 