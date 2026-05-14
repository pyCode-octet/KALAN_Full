class LeaderboardEntryModel {
  final int? id;
  final String userId;
  final String pseudo;
  final int points;
  final int? position;
  final String scope;
  final DateTime lastUpdated;
  final String? avatar;

  LeaderboardEntryModel({
    this.id,
    required this.userId,
    required this.pseudo,
    required this.points,
    this.position,
    this.scope = 'national',
    required this.lastUpdated,
    this.avatar,
  });

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> map) => LeaderboardEntryModel(
        id: map['id'],
        userId: map['user_id'],
        pseudo: map['pseudo'] ?? 'Anonyme',
        points: map['points'] ?? 0,
        position: map['position'],
        scope: map['scope'] ?? 'national',
        lastUpdated: DateTime.parse(map['last_updated'] ?? DateTime.now().toIso8601String()),
        avatar: map['avatar'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'points': points,
        'position': position,
        'scope': scope,
        'last_updated': lastUpdated.toIso8601String(),
      };

  factory LeaderboardEntryModel.fromSupabaseJson(Map<String, dynamic> json) => LeaderboardEntryModel(
        userId: json['user_id'],
        pseudo: json['pseudo'] ?? 'Anonyme',
        points: json['points'] ?? 0,
        position: json['position'],
        scope: json['scope'] ?? 'national',
        lastUpdated: DateTime.parse(json['last_updated']),
        avatar: json['avatar'],
      );
}
