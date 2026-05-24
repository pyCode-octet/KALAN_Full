abstract class UserRepository {
  Future<Map<String, dynamic>> getUserProfile();
  Future<void> updateUserProfile({String? pseudo, String? avatar, int? avatarId, String? school, String? className, String? firstName, String? lastName});
  Future<Map<String, dynamic>> getUserStats(String userId);
  Future<List<Map<String, dynamic>>> getUserBadges(String userId);
  Future<List<Map<String, dynamic>>> getRecentActivity(String userId);
  Future<void> addPoints(int points);
  
  // Friend Management
  Future<List<Map<String, dynamic>>> searchUsers(String pseudo);
  Future<void> addFriend(Map<String, dynamic> friendData);
  Future<List<Map<String, dynamic>>> getFriends();
}
