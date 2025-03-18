// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chore.dart';
import '../models/reward.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get families => _firestore.collection('families');
  CollectionReference get chores => _firestore.collection('chores');
  CollectionReference get rewards => _firestore.collection('rewards');

  // Create a new user document
  Future<void> createUserProfile(String uid, String name, bool isParent, {String? familyId}) {
    return users.doc(uid).set({
      'name': name,
      'isParent': isParent,
      'familyId': familyId ?? '',
      'points': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new family
  Future<DocumentReference> createFamily(String parentUid, String familyName) {
    String familyCode = _generateFamilyCode();
    return families.add({
      'name': familyName,
      'parentIds': [parentUid],
      'childrenIds': [],
      'familyCode': familyCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Generate a random family code
  String _generateFamilyCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'FAM-' + random.substring(random.length - 4);
  }

  // Find a family by code
  Future<QuerySnapshot> findFamilyByCode(String code) {
    return families.where('familyCode', isEqualTo: code).get();
  }

  // Add a child to a family
  Future<void> addChildToFamily(String familyId, String childId) {
    return families.doc(familyId).update({
      'childrenIds': FieldValue.arrayUnion([childId]),
    });
  }

  // Add a chore
  Future<DocumentReference> addChore(Chore chore, String familyId) {
    return chores.add({
      'title': chore.title,
      'description': chore.description,
      'deadline': chore.deadline,
      'isCompleted': chore.isCompleted,
      'reward': chore.reward,
      'priority': chore.priority,
      'familyId': familyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get chores for a family
  Future<QuerySnapshot> getChoresForFamily(String familyId) {
    return chores
        .where('familyId', isEqualTo: familyId)
        .get();
  }

  // Update chore completion status
  Future<void> updateChoreStatus(String choreId, bool isCompleted) {
    return chores.doc(choreId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? FieldValue.serverTimestamp() : null
    });
  }

  // Add a reward
  Future<DocumentReference> addReward(Reward reward, String familyId) {
    return rewards.add({
      'title': reward.title,
      'description': reward.description,
      'pointsRequired': reward.pointsRequired,
      'tier': reward.tier,
      'isRedeemed': reward.isRedeemed,
      'familyId': familyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get rewards for a family
  Future<QuerySnapshot> getRewardsForFamily(String familyId) {
    return rewards
        .where('familyId', isEqualTo: familyId)
        .get();
  }
  
  // Redeem a reward
  Future<void> redeemReward(String rewardId, String childId, int pointsRequired) async {
    // Start a transaction to ensure data consistency
    return _firestore.runTransaction((transaction) async {
      // Get current user points
      DocumentSnapshot userSnapshot = await transaction.get(users.doc(childId));
      int currentPoints = userSnapshot.get('points') ?? 0;
      
      if (currentPoints < pointsRequired) {
        throw Exception('Not enough points');
      }
      
      // Update user points
      transaction.update(users.doc(childId), {
        'points': currentPoints - pointsRequired
      });
      
      // Mark reward as redeemed
      transaction.update(rewards.doc(rewardId), {
        'isRedeemed': true,
        'redeemedAt': FieldValue.serverTimestamp(),
        'redeemedBy': childId
      });
    });
  }
  
  // Add points to a child when a chore is completed and approved
  Future<void> awardPointsForChore(String childId, int points) async {
    DocumentSnapshot userSnapshot = await users.doc(childId).get();
    int currentPoints = userSnapshot.get('points') ?? 0;
    
    return users.doc(childId).update({
      'points': currentPoints + points
    });
  }
  
  // Get child's points
  Future<int> getChildPoints(String childId) async {
    DocumentSnapshot userSnapshot = await users.doc(childId).get();
    return userSnapshot.get('points') ?? 0;
  }
}