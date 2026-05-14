class FlashcardModel {
  final int? id;
  final String uuid;
  final String deckId;
  final String question;
  final String answer;
  final int difficulty;
  final DateTime? nextReview;
  final int interval;
  final int repetitions;
  final DateTime createdAt;
  final bool isSynced;

  FlashcardModel({
    this.id,
    required this.uuid,
    required this.deckId,
    required this.question,
    required this.answer,
    this.difficulty = 1,
    this.nextReview,
    this.interval = 0,
    this.repetitions = 0,
    required this.createdAt,
    this.isSynced = false,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> map) => FlashcardModel(
        id: map['id'],
        uuid: map['uuid'],
        deckId: map['deck_id'],
        question: map['question'],
        answer: map['answer'],
        difficulty: map['difficulty'] ?? 1,
        nextReview: map['next_review'] != null ? DateTime.tryParse(map['next_review']) : null,
        interval: map['interval'] ?? 0,
        repetitions: map['repetitions'] ?? 0,
        createdAt: DateTime.parse(map['created_at']),
        isSynced: map['is_synced'] == 1,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'deck_id': deckId,
        'question': question,
        'answer': answer,
        'difficulty': difficulty,
        'next_review': nextReview?.toIso8601String(),
        'interval': interval,
        'repetitions': repetitions,
        'created_at': createdAt.toIso8601String(),
        'is_synced': isSynced ? 1 : 0,
      };

  Map<String, dynamic> toSupabaseJson() => {
        'uuid': uuid,
        'deck_id': deckId,
        'question': question,
        'answer': answer,
        'difficulty': difficulty,
        'next_review': nextReview?.toIso8601String(),
        'interval': interval,
        'repetitions': repetitions,
        'created_at': createdAt.toIso8601String(),
      };

  factory FlashcardModel.fromSupabaseJson(Map<String, dynamic> json) => FlashcardModel(
        uuid: json['uuid'],
        deckId: json['deck_id'],
        question: json['question'],
        answer: json['answer'],
        difficulty: json['difficulty'] ?? 1,
        nextReview: json['next_review'] != null ? DateTime.tryParse(json['next_review']) : null,
        interval: json['interval'] ?? 0,
        repetitions: json['repetitions'] ?? 0,
        createdAt: DateTime.parse(json['created_at']),
        isSynced: true,
      );
}
