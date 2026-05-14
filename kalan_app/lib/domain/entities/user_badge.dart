class UserBadge {
  final String? id;
  final String userId;
  final String badgeKey;
  final DateTime unlockedAt;

  UserBadge({
    this.id,
    required this.userId,
    required this.badgeKey,
    required this.unlockedAt,
  });
}
