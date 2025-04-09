// lib/models/reward.dart
class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String tier; // 'bronze', 'silver', 'gold'
  final bool isRedeemed;
  final String? redeemedBy; // Child ID who redeemed the reward
  final DateTime? redeemedAt; // When the reward was redeemed
  final String? imageUrl; // Optional image for the reward

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.tier,
    this.isRedeemed = false,
    this.redeemedBy,
    this.redeemedAt,
    this.imageUrl,
  });

  // Create a Reward from Firestore data
  factory Reward.fromFirestore(String id, Map<String, dynamic> data) {
    return Reward(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      pointsRequired: data['pointsRequired'] is int 
          ? data['pointsRequired'] 
          : int.tryParse(data['pointsRequired']?.toString() ?? '0') ?? 0,
      tier: data['tier'] ?? 'bronze',
      isRedeemed: data['isRedeemed'] ?? false,
      redeemedBy: data['redeemedBy'],
      redeemedAt: data['redeemedAt'] != null 
          ? (data['redeemedAt']).toDate()
          : null,
      imageUrl: data['imageUrl'],
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'pointsRequired': pointsRequired,
      'tier': tier,
      'isRedeemed': isRedeemed,
      'redeemedBy': redeemedBy,
      'redeemedAt': redeemedAt,
      'imageUrl': imageUrl,
    };
  }

  // Create a copy with updated fields
  Reward copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsRequired,
    String? tier,
    bool? isRedeemed,
    String? redeemedBy,
    DateTime? redeemedAt,
    String? imageUrl,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      tier: tier ?? this.tier,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedBy: redeemedBy ?? this.redeemedBy,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}