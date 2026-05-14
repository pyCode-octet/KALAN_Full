import '../entities/user_badge.dart';

abstract class BadgeRepository {
  Future<List<UserBadge>> getUserBadges();
  Future<void> unlockBadge(String badgeKey);
}
