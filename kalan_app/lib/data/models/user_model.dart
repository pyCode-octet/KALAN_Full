class UserModel {
  final int? id;
  final String uuid;
  final String pseudo;
  final String? firstName;
  final String? lastName;
  final int? schoolId;
  final int? classId;
  final String? className;
  final String language;
  final int points;
  final int level;
  final int streak;
  final bool isGuest;
  final int? avatarId;
  final DateTime? lastActive;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.uuid,
    required this.pseudo,
    this.firstName,
    this.lastName,
    this.schoolId,
    this.classId,
    this.className,
    this.language = 'fr',
    this.points = 0,
    this.level = 1,
    this.streak = 0,
    this.isGuest = false,
    this.avatarId,
    this.lastActive,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        uuid: map['uuid'],
        pseudo: map['pseudo'],
        firstName: map['firstName'],
        lastName: map['lastName'],
        schoolId: map['school_id'],
        classId: map['class_id'],
        className: map['class'],
        language: map['language'] ?? 'fr',
        points: map['points'] ?? 0,
        level: map['level'] ?? 1,
        streak: map['streak'] ?? 0,
        isGuest: (map['is_guest'] ?? 0) == 1,
        avatarId: map['avatar_id'],
        lastActive: map['last_active'] != null ? DateTime.tryParse(map['last_active']) : null,
        createdAt: DateTime.parse(map['created_at']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'pseudo': pseudo,
        'firstName': firstName,
        'lastName': lastName,
        'school_id': schoolId,
        'class_id': classId,
        'class': className,
        'language': language,
        'points': points,
        'level': level,
        'streak': streak,
        'is_guest': isGuest ? 1 : 0,
        'avatar_id': avatarId,
        'last_active': lastActive?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toSupabaseJson() => {
        'uuid': uuid,
        'pseudo': pseudo,
        'first_name': firstName,
        'last_name': lastName,
        'school_id': schoolId,
        'class_id': classId,
        'language': language,
        'points': points,
        'level': level,
        'streak': streak,
        'avatar_url': avatarId != null ? 'assets/avatars/avatar$avatarId.png' : null,
        'last_active': lastActive?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
