class LeaderboardEntry {
  final String? id;
  final String userId;
  final String pseudo;
  final int points;
  final int? position;
  final String scope;
  final DateTime lastUpdated;
  final String? avatar;

  LeaderboardEntry({
    this.id,
    required this.userId,
    required this.pseudo,
    required this.points,
    this.position,
    this.scope = 'national',
    required this.lastUpdated,
    this.avatar,
  });
}
