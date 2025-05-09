// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chore.dart';
import '../models/reward.dart';
import '../models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get families => _firestore.collection('families');
  CollectionReference get chores => _firestore.collection('chores');
  CollectionReference get rewards => _firestore.collection('rewards');

  // Create a new parent user profile
  Future<void> createParentProfile(String uid, String name, String email, {String? familyId}) {
    return users.doc(uid).set({
      'name': name,
      'email': email,
      'isParent': true,
      'familyId': familyId ?? '',
      'points': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new child user profile
  Future<void> createChildProfile(String uid, String name, String familyId) {
    return users.doc(uid).set({
      'name': name,
      'isParent': false,
      'familyId': familyId,
      'points': 0,
      'completedChores': [],
      'redeemedRewards': [],
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

  // Generate a unique family code
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

  // Get user by ID
  Future<User> getUserById(String userId) async {
    DocumentSnapshot doc = await users.doc(userId).get();
    if (!doc.exists) {
      throw Exception('User not found');
    }
    
    return User.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Get all children in a family
  Future<List<Child>> getChildrenInFamily(String familyId) async {
    QuerySnapshot snapshot = await users
        .where('familyId', isEqualTo: familyId)
        .where('isParent', isEqualTo: false)
        .get();
    
    return snapshot.docs.map((doc) {
      return Child.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Add a chore
  Future<DocumentReference> addChore(Chore chore, String familyId) {
    return chores.add({
      ...chore.toFirestore(),
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

  // Get chores assigned to a specific child
  Future<List<Chore>> getChoresForChild(String childId, String familyId) async {
    QuerySnapshot snapshot = await chores
        .where('familyId', isEqualTo: familyId)
        .where('assignedTo', arrayContains: childId)
        .get();
    
    return snapshot.docs.map((doc) {
      return Chore.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // Update chore completion status
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
      Child child = Child.fromFirestore(childId, childDoc.data() as Map<String, dynamic>);
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

  // Add a reward
  Future<DocumentReference> addReward(Reward reward, String familyId) {
    return rewards.add({
      ...reward.toFirestore(),
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
  Future<void> redeemReward(String rewardId, String childId) async {
    // Start a transaction to ensure data consistency
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot rewardDoc = await transaction.get(rewards.doc(rewardId));
      DocumentSnapshot childDoc = await transaction.get(users.doc(childId));
      
      if (!rewardDoc.exists || !childDoc.exists) {
        throw Exception('Reward or child not found');
      }
      
      Map<String, dynamic> rewardData = rewardDoc.data() as Map<String, dynamic>;
      if (rewardData['isRedeemed'] == true) {
        throw Exception('Reward already redeemed');
      }
      
      Child child = Child.fromFirestore(childId, childDoc.data() as Map<String, dynamic>);
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
  
  // Get child's points
  Future<int> getChildPoints(String childId) async {
    DocumentSnapshot userSnapshot = await users.doc(childId).get();
    if (!userSnapshot.exists) {
      throw Exception('Child not found');
    }
    return userSnapshot.get('points') ?? 0;
  }
  
  // Get pending chores (not completed) for a family
  Future<List<Chore>> getPendingChores(String familyId) async {
    QuerySnapshot snapshot = await chores
        .where('familyId', isEqualTo: familyId)
        .where('isCompleted', isEqualTo: false)
        .get();
    
    return snapshot.docs.map((doc) {
      return Chore.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }
  
  // Get completed chores for a family
  Future<List<Chore>> getCompletedChores(String familyId) async {
    QuerySnapshot snapshot = await chores
        .where('familyId', isEqualTo: familyId)
        .where('isCompleted', isEqualTo: true)
        .get();
    
    return snapshot.docs.map((doc) {
      return Chore.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }
  
  // Mark a chore as pending approval
  Future<void> markChorePendingApproval(String choreId, String childId) {
    return chores.doc(choreId).update({
      'isPendingApproval': true,
      'completedBy': childId,
      'completedAt': FieldValue.serverTimestamp()
    });
  }
  
  // Approve a chore and award points to child
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
      Child child = Child.fromFirestore(childId, childDoc.data() as Map<String, dynamic>);
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
  
  // Award points to a child (simpler version without transaction)
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
  
  // Create a test family with a predictable family code (for debugging)
  Future<DocumentReference> createTestFamily(String parentUid, String familyName) async {
    const String testFamilyCode = 'TEST-1234';
    
    // Check if family with this code already exists
    final existingFamilies = await findFamilyByCode(testFamilyCode);
    if (existingFamilies.docs.isNotEmpty) {
      return _firestore.collection('families').doc(existingFamilies.docs.first.id);
    }
    
    // Create a new test family with a fixed code
    return families.add({
      'name': familyName,
      'parentIds': [parentUid],
      'childrenIds': [],
      'familyCode': testFamilyCode,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': parentUid,
    });
  }
  
  // Get rewards by tier
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
}