// lib/widgets/reward_card.dart
import 'package:flutter/material.dart';
import '../models/reward.dart';

class RewardCard extends StatelessWidget {
  final Reward reward;
  final Function(String, int)? onRedeem;

  const RewardCard({
    Key? key,
    required this.reward,
    this.onRedeem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getTierColor(reward.tier),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reward.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
                          _getTierText(reward.tier),
                          style: TextStyle(
                            color: _getTierColor(reward.tier),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onRedeem != null && !reward.isRedeemed)
                  ElevatedButton(
                    onPressed: () => onRedeem!(reward.id, reward.pointsRequired),
                    child: const Text('Redeem'),
                  ),
                if (reward.isRedeemed)
                  const Chip(
                    label: Text('Redeemed'),
                    backgroundColor: Colors.grey,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(reward.description),
            const SizedBox(height: 8),
            Text(
              'Points Required: ${reward.pointsRequired}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      case 'bronze':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getTierText(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return 'Gold Tier';
      case 'silver':
        return 'Silver Tier';
      case 'bronze':
        return 'Bronze Tier';
      default:
        return 'Basic Tier';
    }
  }
}