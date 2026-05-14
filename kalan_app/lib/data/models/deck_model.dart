class DeckModel {
  final int? id;
  final String uuid;
  final String userId;
  final String title;
  final String? description;
  final String? subject;
  final String? level;
  final bool isPublic;
  final int downloadCount;
  final DateTime createdAt;
  final bool isSynced;

  DeckModel({
    this.id,
    required this.uuid,
    required this.userId,
    required this.title,
    this.description,
    this.subject,
    this.level,
    this.isPublic = false,
    this.downloadCount = 0,
    required this.createdAt,
    this.isSynced = false,
  });

  factory DeckModel.fromMap(Map<String, dynamic> map) => DeckModel(
        id: map['id'],
        uuid: map['uuid'],
        userId: map['user_id'],
        title: map['title'],
        description: map['description'],
        subject: map['subject'],
        level: map['level'],
        isPublic: map['is_public'] == 1,
        downloadCount: map['download_count'] ?? 0,
        createdAt: DateTime.parse(map['created_at']),
        isSynced: map['is_synced'] == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'user_id': userId,
        'title': title,
        'description': description,
        'subject': subject,
        'level': level,
        'is_public': isPublic ? 1 : 0,
        'download_count': downloadCount,
        'created_at': createdAt.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  Map<String, dynamic> toSupabaseJson() => {
        'uuid': uuid,
        'user_id': userId,
        'title': title,
        'description': description,
        'subject': subject,
        'level': level,
        'is_public': isPublic,
        'download_count': downloadCount,
        'created_at': createdAt.toIso8601String(),
      };

  factory DeckModel.fromSupabaseJson(Map<String, dynamic> json) => DeckModel(
        uuid: json['uuid'],
        userId: json['user_id'],
        title: json['title'],
        description: json['description'],
        subject: json['subject'],
        level: json['level'],
        isPublic: json['is_public'] ?? false,
        downloadCount: json['download_count'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
        isSynced: true,
      );
}
