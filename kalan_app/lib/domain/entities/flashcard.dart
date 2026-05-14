class Flashcard {
  final String uuid;
  final String question;
  final String answer;
  final int difficulty;
  final DateTime? nextReview;
  final int interval;
  final int repetitions;

  Flashcard({
    required this.uuid,
    required this.question,
    required this.answer,
    this.difficulty = 1,
    this.nextReview,
    this.interval = 0,
    this.repetitions = 0,
  });
}
