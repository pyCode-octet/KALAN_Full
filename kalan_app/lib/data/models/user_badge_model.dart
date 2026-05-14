class UserBadgeModel {
  final int? id;
  final String userId;
  final String badgeKey;
  final DateTime unlockedAt;

  UserBadgeModel({
    this.id,
    required this.userId,
    required this.badgeKey,
    required this.unlockedAt,
  });

  factory UserBadgeModel.fromMap(Map<String, dynamic> map) => UserBadgeModel(
        id: map['id'],
        userId: map['user_id'],
        badgeKey: map['badge_key'],
        unlockedAt: DateTime.parse(map['unlocked_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'badge_key': badgeKey,
        'unlocked_at': unlockedAt.toIso8601String(),
      };

  factory UserBadgeModel.fromSupabaseJson(Map<String, dynamic> json) => UserBadgeModel(
        userId: json['user_id'],
        badgeKey: json['badge_key'],
        unlockedAt: DateTime.parse(json['unlocked_at']),
      );

  Map<String, dynamic> toSupabaseJson() => {
        'user_id': userId,
        'badge_key': badgeKey,
        'unlocked_at': unlockedAt.toIso8601String(),
      };
}
