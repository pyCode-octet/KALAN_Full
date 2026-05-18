import '../entities/user_badge.dart';

abstract class BadgeRepository {
  Future<List<UserBadge>> getUserBadges();
  Future<List<Map<String, dynamic>>> getAllBadges(); // Retourne les définitions de badges
  Future<void> unlockBadge(String badgeKey);
}
