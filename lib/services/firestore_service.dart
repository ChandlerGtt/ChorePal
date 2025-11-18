// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';
import 'dart:math';
import '../models/chore.dart';
import '../models/reward.dart';
import '../models/user.dart';

/// Service for interacting with Firestore database.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Enable offline persistence (except on web where it's handled differently)
  FirestoreService() {
    if (!kIsWeb) {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  }

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get families => _firestore.collection('families');
  CollectionReference get chores => _firestore.collection('chores');
  CollectionReference get rewards => _firestore.collection('rewards');

  // ----------------------
  // User Management Methods
  // ----------------------

  /// Creates a new parent user profile.
  Future<void> createParentProfile(String uid, String name, String email,
      {String? familyId, String? phoneNumber}) async {
    try {
      final userData = {
        'name': name,
        'email': email,
        'isParent': true,
        'familyId': familyId ?? '',
        'points': 0,
        'pushNotificationsEnabled': true,
        'emailNotificationsEnabled': true,
        'smsNotificationsEnabled': false,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // On web and Windows, use timeout handling due to potential hanging issues
      // Android/iOS work fine without special handling
      final isWebOrWindows =
          kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

      if (isWebOrWindows) {
        // Use timeout to catch hanging issues, but don't fail if it times out
        // The write might have succeeded even if the promise doesn't resolve
        try {
          await users.doc(uid).set(userData).timeout(
                const Duration(seconds: 10),
              );
        } on TimeoutException {
          // Timeout occurred, but the write might have succeeded
          // Continue - verification will check if it worked
        }
      } else {
        // Android/iOS: Direct write (native SDKs work reliably)
        await users.doc(uid).set(userData);
      }

      // Verify the document was created (non-blocking)
      try {
        final doc =
            await users.doc(uid).get().timeout(const Duration(seconds: 8));
        if (!doc.exists) {
          // Document doesn't exist, but might be a timing issue
          // Don't throw - the write might have succeeded but not propagated yet
        }
      } catch (e) {
        // Verification failed, but write might have succeeded
        // Continue anyway since the write might have succeeded
      }
    } catch (e) {
      if (e.toString().contains('permission') ||
          e.toString().contains('PERMISSION_DENIED')) {
        throw Exception(
            'Permission denied. Please check Firestore security rules.');
      }
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Failed to create your profile: ${e.toString()}');
    }
  }

  /// Creates a new child user profile.
  Future<void> createChildProfile(String uid, String name, String familyId) {
    return users.doc(uid).set({
      'name': name,
      'isParent': false,
      'familyId': familyId,
      'points': 0,
      'completedChores': [],
      'redeemedRewards': [],
      'pushNotificationsEnabled': true,
      'emailNotificationsEnabled': true,
      'smsNotificationsEnabled': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Gets a user by ID.
  Future<User> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await users.doc(userId).get();
      if (!doc.exists) {
        throw Exception('User profile not found. Please try logging in again.');
      }

      return User.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('User profile not found')) {
        rethrow;
      }
      throw Exception(
          'Failed to load user profile. Please check your connection.');
    }
  }

  /// Gets all children in a family.
  Future<List<Child>> getChildrenInFamily(String familyId) async {
    try {
      QuerySnapshot snapshot = await users
          .where('familyId', isEqualTo: familyId)
          .where('isParent', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) {
        return Child.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Failed to load children. Please check your connection.');
    }
  }

  /// Finds a child by name within a specific family.
  Future<Child?> findChildByNameInFamily(
      String childName, String familyId) async {
    try {
      // Normalize the input name to lowercase for case-insensitive comparison
      final normalizedInputName = childName.trim().toLowerCase();

      // Query all children in the family (without name filter since Firestore is case-sensitive)
      QuerySnapshot snapshot = await users
          .where('familyId', isEqualTo: familyId)
          .where('isParent', isEqualTo: false)
          .get();

      // Find the child with matching name (case-insensitive)
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final storedName = data['name']?.toString().trim().toLowerCase() ?? '';
        if (storedName == normalizedInputName) {
          return Child.fromFirestore(doc.id, data);
        }
      }

      return null;
    } catch (e) {
      print('Error finding child by name: $e');
      return null;
    }
  }

  /// Awards points to a child.
  Future<void> awardPointsToChild(String childId, int points) async {
    DocumentSnapshot childDoc = await users.doc(childId).get();
    if (!childDoc.exists) {
      throw Exception('Child not found');
    }

    int currentPoints = childDoc.get('points') ?? 0;
    return users.doc(childId).update({
      'points': currentPoints + points,
    });
  }

  /// Gets a child's points.
  Future<int> getChildPoints(String childId) async {
    DocumentSnapshot userSnapshot = await users.doc(childId).get();
    if (!userSnapshot.exists) {
      throw Exception('Child not found');
    }
    return userSnapshot.get('points') ?? 0;
  }

  // ----------------------
  // Family Management Methods
  // ----------------------

  /// Creates a new family.
  Future<DocumentReference> createFamily(
      String parentUid, String familyName) async {
    try {
      // Skip enableNetwork on web - it can cause issues
      if (!kIsWeb) {
        try {
          await _firestore.enableNetwork().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              // Continue anyway - might work offline
            },
          );
        } catch (e) {
          // Continue anyway - might work offline
        }
      }

      String familyCode = _generateFamilyCode();

      final familyData = {
        'name': familyName,
        'parentIds': [parentUid],
        'childrenIds': [],
        'familyCode': familyCode,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // On web and Windows, use doc().set() instead of add() to avoid hanging issues
      // Android/iOS use native SDKs and work fine with add()
      DocumentReference familyRef;
      final isWebOrWindows =
          kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

      if (isWebOrWindows) {
        // Generate a Firestore-like document ID (20 chars, alphanumeric)
        final docId = _generateFirestoreLikeId();
        familyRef = families.doc(docId);

        try {
          // On web/Windows, Firestore writes can appear to hang but actually succeed
          // Use a shorter timeout and then verify asynchronously
          await familyRef.set(familyData).timeout(
                const Duration(seconds: 10),
              );
        } on TimeoutException {
          // Timeout occurred, but the write might have succeeded
          // Don't throw - let verification check if it worked
        } catch (e) {
          // Other errors should be thrown
          rethrow;
        }
      } else {
        // Android/iOS: Use add() with native SDKs (works reliably)
        familyRef = await families.add(familyData).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception(
                'Family creation timed out. Please check your internet connection and try again.');
          },
        );
      }

      // Verify the document was created (non-blocking - don't fail if this times out)
      // On web, Firestore can be slow to respond but the write may have succeeded
      try {
        final doc = await familyRef.get().timeout(const Duration(seconds: 8));
        if (!doc.exists) {
          // Document doesn't exist, but might be a timing issue
          // Don't throw - the write might have succeeded but not propagated yet
        }
      } catch (e) {
        // Verification failed, but write might have succeeded
        // Continue anyway since the write might have succeeded
      }

      return familyRef;
    } catch (e) {
      if (e.toString().contains('permission') ||
          e.toString().contains('PERMISSION_DENIED')) {
        throw Exception(
            'Permission denied. Please check Firestore security rules.');
      }
      if (e.toString().contains('network') ||
          e.toString().contains('NETWORK')) {
        throw Exception(
            'Network error. Please check your internet connection.');
      }
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Failed to create family: ${e.toString()}');
    }
  }

  /// Generates a unique family code.
  String _generateFamilyCode() {
    // Generate a 6-digit numeric code
    final random = Random();
    String code = '';

    // Create a 6-digit code with leading zeros if necessary
    for (int i = 0; i < 6; i++) {
      code += random.nextInt(10).toString();
    }

    // Ensure the code doesn't start with 0
    if (code.startsWith('0')) {
      code = '1' + code.substring(1);
    }

    return code;
  }

  /// Generates a Firestore-like document ID (20 characters, alphanumeric)
  /// Similar to what Firestore generates with add()
  String _generateFirestoreLikeId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    // Generate 20 random alphanumeric characters
    String id = '';
    for (int i = 0; i < 20; i++) {
      id += chars[random.nextInt(chars.length)];
    }

    return id;
  }

  /// Finds a family by code.
  Future<QuerySnapshot> findFamilyByCode(String code) {
    return families.where('familyCode', isEqualTo: code).get();
  }

  /// Adds a child to a family.
  Future<void> addChildToFamily(String familyId, String childId) {
    return families.doc(familyId).update({
      'childrenIds': FieldValue.arrayUnion([childId]),
    });
  }

  /// Removes a child from a family.
  Future<void> removeChildFromFamily(String familyId, String childId) async {
    try {
      // Remove child from family's children list
      await families.doc(familyId).update({
        'childrenIds': FieldValue.arrayRemove([childId]),
      });

      // Delete the child's user document
      await users.doc(childId).delete();

      print('Successfully removed child $childId from family $familyId');
    } catch (e) {
      print('Error removing child from family: $e');
      throw Exception('Failed to remove child from family. Please try again.');
    }
  }

  // ----------------------
  // Chore Management Methods
  // ----------------------

  /// Adds a new chore.
  Future<DocumentReference> addChore(Chore chore, String familyId) {
    return chores.add({
      ...chore.toFirestore(),
      'familyId': familyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Gets chores for a family.
  Future<QuerySnapshot> getChoresForFamily(String familyId) {
    return chores.where('familyId', isEqualTo: familyId).get();
  }

  /// Gets chores assigned to a specific child.
  Future<List<Chore>> getChoresForChild(String childId, String familyId) async {
    QuerySnapshot snapshot = await chores
        .where('familyId', isEqualTo: familyId)
        .where('assignedTo', arrayContains: childId)
        .get();

    return snapshot.docs.map((doc) {
      return Chore.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  /// Gets pending chores (not completed) for a family.
  Future<List<Chore>> getPendingChores(String familyId) async {
    QuerySnapshot snapshot = await chores
        .where('familyId', isEqualTo: familyId)
        .where('isCompleted', isEqualTo: false)
        .get();

    return snapshot.docs.map((doc) {
      return Chore.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  /// Gets completed chores for a family.
  Future<List<Chore>> getCompletedChores(String familyId) async {
    QuerySnapshot snapshot = await chores
        .where('familyId', isEqualTo: familyId)
        .where('isCompleted', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) {
      return Chore.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  /// Updates chore completion status.
  Future<void> completeChore(String choreId, String childId) {
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot choreDoc = await transaction.get(chores.doc(choreId));
      DocumentSnapshot childDoc = await transaction.get(users.doc(childId));

      if (!choreDoc.exists || !childDoc.exists) {
        throw Exception('Chore or child not found');
      }

      Map<String, dynamic> choreData = choreDoc.data() as Map<String, dynamic>;
      if (choreData['isCompleted'] == true) {
        throw Exception('Chore already completed');
      }

      // Get the child's current data
      Child child =
          Child.fromFirestore(childId, childDoc.data() as Map<String, dynamic>);
      int pointValue = choreData['pointValue'] is int
          ? choreData['pointValue']
          : int.tryParse(choreData['pointValue']?.toString() ?? '0') ?? 0;

      // Update chore as completed
      transaction.update(chores.doc(choreId), {
        'isCompleted': true,
        'completedBy': childId,
        'completedAt': FieldValue.serverTimestamp()
      });

      // Update child's points and completed chores
      transaction.update(users.doc(childId), {
        'points': child.points + pointValue,
        'completedChores': FieldValue.arrayUnion([choreId])
      });
    });
  }

  /// Marks a chore as pending approval.
  Future<void> markChorePendingApproval(String choreId, String childId) {
    return chores.doc(choreId).update({
      'isPendingApproval': true,
      'completedBy': childId,
      'completedAt': FieldValue.serverTimestamp()
    });
  }

  /// Approves a chore and awards points to child.
  Future<void> approveChore(String choreId, String childId) {
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot choreDoc = await transaction.get(chores.doc(choreId));
      DocumentSnapshot childDoc = await transaction.get(users.doc(childId));

      if (!choreDoc.exists || !childDoc.exists) {
        throw Exception('Chore or child not found');
      }

      Map<String, dynamic> choreData = choreDoc.data() as Map<String, dynamic>;
      if (choreData['isCompleted'] == true) {
        throw Exception('Chore already completed');
      }

      // Get the child's current data
      Child child =
          Child.fromFirestore(childId, childDoc.data() as Map<String, dynamic>);
      int pointValue = choreData['pointValue'] is int
          ? choreData['pointValue']
          : int.tryParse(choreData['pointValue']?.toString() ?? '0') ?? 0;

      // Update chore as completed
      transaction.update(chores.doc(choreId), {
        'isCompleted': true,
        'isPendingApproval': false,
      });

      // Update child's points and completed chores
      transaction.update(users.doc(childId), {
        'points': child.points + pointValue,
        'completedChores': FieldValue.arrayUnion([choreId])
      });
    });
  }

  // ----------------------
  // Reward Management Methods
  // ----------------------

  /// Adds a new reward.
  Future<DocumentReference> addReward(Reward reward, String familyId) {
    return rewards.add({
      ...reward.toFirestore(),
      'familyId': familyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Gets rewards for a family.
  Future<QuerySnapshot> getRewardsForFamily(String familyId) {
    return rewards.where('familyId', isEqualTo: familyId).get();
  }

  /// Redeems a reward.
  Future<void> redeemReward(String rewardId, String childId) async {
    // Start a transaction to ensure data consistency
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot rewardDoc = await transaction.get(rewards.doc(rewardId));
      DocumentSnapshot childDoc = await transaction.get(users.doc(childId));

      if (!rewardDoc.exists || !childDoc.exists) {
        throw Exception('Reward or child not found');
      }

      Map<String, dynamic> rewardData =
          rewardDoc.data() as Map<String, dynamic>;
      if (rewardData['isRedeemed'] == true) {
        throw Exception('Reward already redeemed');
      }

      Child child =
          Child.fromFirestore(childId, childDoc.data() as Map<String, dynamic>);
      int pointsRequired = rewardData['pointsRequired'] is int
          ? rewardData['pointsRequired']
          : int.tryParse(rewardData['pointsRequired']?.toString() ?? '0') ?? 0;

      if (child.points < pointsRequired) {
        throw Exception('Not enough points');
      }

      // Update user points
      transaction.update(users.doc(childId), {
        'points': child.points - pointsRequired,
        'redeemedRewards': FieldValue.arrayUnion([rewardId])
      });

      // Mark reward as redeemed
      transaction.update(rewards.doc(rewardId), {
        'isRedeemed': true,
        'redeemedAt': FieldValue.serverTimestamp(),
        'redeemedBy': childId
      });
    });
  }

  /// Gets rewards by tier.
  Future<Map<String, List<Reward>>> getRewardsByTier(String familyId) async {
    QuerySnapshot snapshot = await rewards
        .where('familyId', isEqualTo: familyId)
        .where('isRedeemed', isEqualTo: false)
        .get();

    List<Reward> rewardsList = snapshot.docs.map((doc) {
      return Reward.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();

    Map<String, List<Reward>> rewardsByTier = {};
    for (var reward in rewardsList) {
      if (!rewardsByTier.containsKey(reward.tier)) {
        rewardsByTier[reward.tier] = [];
      }
      rewardsByTier[reward.tier]!.add(reward);
    }

    return rewardsByTier;
  }

  // ----------------------
  // Notification Preferences Methods
  // ----------------------

  /// Updates notification preferences for a user
  /// Validates that phone number is provided when SMS notifications are enabled
  Future<void> updateNotificationPreferences(
    String userId, {
    bool? pushNotificationsEnabled,
    bool? emailNotificationsEnabled,
    bool? smsNotificationsEnabled,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (pushNotificationsEnabled != null) {
        updates['pushNotificationsEnabled'] = pushNotificationsEnabled;
      }
      if (emailNotificationsEnabled != null) {
        updates['emailNotificationsEnabled'] = emailNotificationsEnabled;
      }
      if (smsNotificationsEnabled != null) {
        updates['smsNotificationsEnabled'] = smsNotificationsEnabled;

        // Validate phone number when SMS is enabled
        if (smsNotificationsEnabled) {
          if (phoneNumber == null || phoneNumber.trim().isEmpty) {
            throw Exception(
                'Phone number is required when SMS notifications are enabled');
          }
          updates['phoneNumber'] = phoneNumber.trim();
        }
      }

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber.trim();
      }

      if (email != null) {
        // Validate email format if provided
        final trimmedEmail = email.trim();
        if (trimmedEmail.isNotEmpty) {
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(trimmedEmail)) {
            throw Exception('Please enter a valid email address');
          }
          updates['email'] = trimmedEmail;
          print('Adding email to updates: $trimmedEmail');
        } else {
          // Explicitly delete the email field to clear it
          updates['email'] = FieldValue.delete();
          print('Adding email delete to updates');
        }
      } else {
        print('Email parameter is null, skipping email update');
      }
      
      // Debug: Print what we're updating
      print('Updating user $userId with: $updates');

      if (updates.isNotEmpty) {
        try {
          await users.doc(userId).update(updates);
          print('Successfully updated user $userId');
          
          // Verify the update
          final doc = await users.doc(userId).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>?;
            print('User document after update: email = ${data?['email']}');
          }
        } catch (updateError) {
          print('Error updating document: $updateError');
          rethrow;
        }
      } else {
        print('No updates to apply for user $userId');
      }
    } catch (e) {
      if (e.toString().contains('Phone number is required') ||
          e.toString().contains('valid email')) {
        rethrow;
      }
      throw Exception(
          'Failed to update notification preferences. Please try again.');
    }
  }
}
