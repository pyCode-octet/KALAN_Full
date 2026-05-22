/// Payload partagé pour synchroniser leaderboard_entries (local + Supabase).
class LeaderboardSyncHelper {
  static String pseudoFromProfile(Map<String, dynamic> profile) =>
      (profile['pseudo'] as String?)?.trim().isNotEmpty == true
          ? profile['pseudo'] as String
          : 'Anonyme';

  static String avatarFromProfile(Map<String, dynamic> profile) {
    final avatarId = profile['avatar_id'];
    if (avatarId != null) return avatarId.toString();
    final avatar = profile['avatar']?.toString();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return '1';
  }

  static Map<String, dynamic> entryPayload({
    required String userId,
    required int points,
    required Map<String, dynamic> profile,
    String scope = 'national',
  }) {
    return {
      'user_id': userId,
      'points': points,
      'scope': scope,
      'pseudo': pseudoFromProfile(profile),
      'avatar': avatarFromProfile(profile),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}
