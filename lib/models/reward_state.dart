// lib/models/reward_state.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'reward.dart';

class RewardState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Reward> _rewards = [];
  String? _familyId;
  bool _isLoading = false;

  List<Reward> get rewards => _rewards;
  bool get isLoading => _isLoading;
  
  // Group rewards by tier
  Map<String, List<Reward>> get rewardsByTier {
    final result = <String, List<Reward>>{};
    for (final reward in _rewards) {
      if (!result.containsKey(reward.tier)) {
        result[reward.tier] = [];
      }
      result[reward.tier]!.add(reward);
    }
    return result;
  }
  
  void setFamilyId(String familyId) {
    _familyId = familyId;
  }

  Future<void> loadRewards() async {
    if (_familyId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _firestoreService.getRewardsForFamily(_familyId!);
      
      _rewards = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Reward(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          pointsRequired: data['pointsRequired'] is int 
              ? data['pointsRequired'] 
              : int.tryParse(data['pointsRequired']?.toString() ?? '0') ?? 0,
          tier: data['tier'] ?? 'bronze',
          isRedeemed: data['isRedeemed'] ?? false,
        );
      }).toList();
    } catch (e) {
      print('Error loading rewards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReward(Reward reward) async {
    if (_familyId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.addReward(reward, _familyId!);
      await loadRewards(); // Reload the rewards
    } catch (e) {
      print('Error adding reward: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> redeemReward(String rewardId, String childId, int pointsRequired) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.redeemReward(rewardId, childId, pointsRequired);
      await loadRewards(); // Reload the rewards
    } catch (e) {
      print('Error redeeming reward: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Rethrow to handle in UI
    }
  }
}