// lib/models/reward_state.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'reward.dart';
import 'user.dart';

class RewardState extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Reward> _rewards = [];
  Map<String, List<Reward>> _rewardsByTier = {};
  String? _familyId;
  bool _isLoading = false;
  String? _errorMessage;

  List<Reward> get rewards => _rewards;
  Map<String, List<Reward>> get rewardsByTier => _rewardsByTier;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  void setFamilyId(String familyId) {
    _familyId = familyId;
  }

  Future<void> loadRewards() async {
    if (_familyId == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final snapshot = await _firestoreService.getRewardsForFamily(_familyId!);
      
      _rewards = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Reward.fromFirestore(doc.id, data);
      }).toList();
      
      // Group rewards by tier
      _rewardsByTier = {};
      for (final reward in _rewards) {
        if (!_rewardsByTier.containsKey(reward.tier)) {
          _rewardsByTier[reward.tier] = [];
        }
        _rewardsByTier[reward.tier]!.add(reward);
      }
      
      // Sort rewards by points required within each tier
      _rewardsByTier.forEach((tier, rewards) {
        rewards.sort((a, b) => a.pointsRequired.compareTo(b.pointsRequired));
      });
    } catch (e) {
      _errorMessage = 'Failed to load rewards. Please check your connection.';
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

  Future<void> redeemReward(String rewardId, String childId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _firestoreService.redeemReward(rewardId, childId);
      await loadRewards(); // Reload the rewards
    } catch (e) {
      print('Error redeeming reward: $e');
      _isLoading = false;
      notifyListeners();
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Get available rewards for a child based on their points
  List<Reward> getAvailableRewardsForChild(Child child) {
    return _rewards.where((reward) => 
      !reward.isRedeemed && reward.pointsRequired <= child.points
    ).toList();
  }
  
  // Get rewards by tier for a specific child, marking which ones they can afford
  Map<String, List<Map<String, dynamic>>> getRewardsByTierForChild(Child child) {
    Map<String, List<Map<String, dynamic>>> result = {};
    
    _rewardsByTier.forEach((tier, rewards) {
      result[tier] = rewards.map((reward) {
        return {
          'reward': reward,
          'canAfford': child.points >= reward.pointsRequired,
        };
      }).toList();
    });
    
    return result;
  }
  
  // Get all redeemed rewards
  List<Reward> getRedeemedRewards() {
    return _rewards.where((reward) => reward.isRedeemed).toList();
  }
  
  // Get a child's redeemed rewards
  List<Reward> getChildRedeemedRewards(String childId) {
    return _rewards.where((reward) => 
      reward.isRedeemed && reward.redeemedBy == childId
    ).toList();
  }
  
  // Get reward history sorted by date
  List<Reward> getRewardHistory({String? childId}) {
    List<Reward> history;
    
    if (childId != null) {
      // Get history for specific child
      history = _rewards.where((reward) => 
        reward.isRedeemed && reward.redeemedBy == childId
      ).toList();
    } else {
      // Get all redeemed rewards
      history = _rewards.where((reward) => reward.isRedeemed).toList();
    }
    
    // Sort by redemption date, most recent first
    history.sort((a, b) {
      final aDate = a.redeemedAt ?? DateTime(1900);
      final bDate = b.redeemedAt ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });
    
    return history;
  }
  
  // Calculate total points spent by a child
  int getPointsSpent(String childId) {
    return getChildRedeemedRewards(childId)
        .fold(0, (sum, reward) => sum + reward.pointsRequired);
  }
}