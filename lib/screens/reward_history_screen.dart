import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reward.dart';
import '../models/reward_state.dart';
import '../models/user_state.dart';
import 'package:intl/intl.dart';

class RewardHistoryScreen extends StatelessWidget {
  final String? childId; // Optional - if passed, shows only this child's history

  const RewardHistoryScreen({Key? key, this.childId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(childId != null ? 'My Reward History' : 'Family Reward History'),
      ),
      body: Consumer2<RewardState, UserState>(
        builder: (context, rewardState, userState, child) {
          final rewards = rewardState.getRewardHistory(childId: childId);
          
          if (rewards.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No reward history yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Redeemed rewards will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              await rewardState.loadRewards();
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rewards.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return _buildHistoryItem(context, reward, userState);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, 
    Reward reward, 
    UserState userState
  ) {
    // Find the child name if available
    String? childName;
    if (reward.redeemedBy != null) {
      final child = userState.getChildById(reward.redeemedBy!);
      childName = child?.name;
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Reward icon with tier color
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getTierColor(reward.tier).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: _getTierColor(reward.tier),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                // Right side: Reward details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reward.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTierColor(reward.tier).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${reward.tier.toUpperCase()} TIER',
                              style: TextStyle(
                                color: _getTierColor(reward.tier),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${reward.pointsRequired} POINTS',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Redeemed by
                if (childName != null && childId == null) ...[
                  Flexible(
                    child: Text(
                      'Redeemed by: $childName',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                // Redeemed date
                if (reward.redeemedAt != null) ...[
                  Text(
                    'Redeemed on: ${DateFormat('MMM d, yyyy').format(reward.redeemedAt!)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return Colors.amber.shade700;
      case 'silver':
        return Colors.blueGrey.shade400;
      case 'bronze':
        return Colors.brown.shade400;
      default:
        return Colors.grey;
    }
  }
} 