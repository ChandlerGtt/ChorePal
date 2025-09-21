import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/reward.dart';
import '../models/reward_state.dart';
import '../models/user_state.dart';
/* unused
import '../models/user.dart';
*/
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
          
          // Group rewards by month
          final groupedRewards = _groupRewardsByMonth(rewards);
          
          return RefreshIndicator(
            onRefresh: () async {
              await rewardState.loadRewards();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedRewards.length,
              itemBuilder: (context, index) {
                final monthKey = groupedRewards.keys.elementAt(index);
                final monthRewards = groupedRewards[monthKey]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month header
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
                      child: Text(
                        monthKey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    // Month rewards
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: monthRewards.length,
                      itemBuilder: (context, rewardIndex) {
                        return _buildCompactHistoryItem(
                          context, 
                          monthRewards[rewardIndex], 
                          userState,
                        );
                      },
                    ),
                    // Add some space between months
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
  
  // Group rewards by month
  Map<String, List<Reward>> _groupRewardsByMonth(List<Reward> rewards) {
    final Map<String, List<Reward>> grouped = {};
    
    for (final reward in rewards) {
      if (reward.redeemedAt != null) {
        final monthKey = DateFormat('MMMM yyyy').format(reward.redeemedAt!);
        
        if (!grouped.containsKey(monthKey)) {
          grouped[monthKey] = [];
        }
        
        grouped[monthKey]!.add(reward);
      }
    }
    
    // Sort the map keys by date (most recent first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final aDate = DateFormat('MMMM yyyy').parse(a);
        final bDate = DateFormat('MMMM yyyy').parse(b);
        return bDate.compareTo(aDate); // Descending order
      });
    
    // Create a new map with the sorted keys
    final Map<String, List<Reward>> sortedGrouped = {};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }
    
    return sortedGrouped;
  }

  Widget _buildCompactHistoryItem(
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
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTierColor(reward.tier).withOpacity(0.2),
          child: Icon(
            Icons.card_giftcard,
            color: _getTierColor(reward.tier),
          ),
        ),
        title: Text(
          reward.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '${reward.pointsRequired} points',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                if (reward.redeemedAt != null) ...[
                  Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(reward.redeemedAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
            if (childName != null && childId == null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.purple.shade700),
                  const SizedBox(width: 4),
                  Text(
                    childName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8, 
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _getTierColor(reward.tier).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            reward.tier.toUpperCase(),
            style: TextStyle(
              color: _getTierColor(reward.tier),
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
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