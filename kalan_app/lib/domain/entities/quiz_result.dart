class QuizResult {
  final String? id;
  final String userId;
  final String? deckId;
  final int score;
  final int total;
  final int durationSeconds;
  final DateTime createdAt;

  QuizResult({
    this.id,
    required this.userId,
    this.deckId,
    required this.score,
    required this.total,
    this.durationSeconds = 0,
    required this.createdAt,
  });
}
