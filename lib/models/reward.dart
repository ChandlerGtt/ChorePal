// lib/models/reward.dart
class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String tier; // 'bronze', 'silver', 'gold'
  final bool isRedeemed;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.tier,
    this.isRedeemed = false,
  });
}