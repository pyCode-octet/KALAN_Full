import '../entities/leaderboard_entry.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({String scope = 'national'});
  Stream<List<LeaderboardEntry>> watchLeaderboard({String scope = 'national'});
  Future<void> updateUserPoints(int points);
}
