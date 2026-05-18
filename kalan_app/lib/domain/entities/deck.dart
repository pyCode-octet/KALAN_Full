class Deck {
  final String uuid;
  final String title;
  final String? description;
  final String? subject;
  final String? level;
  final bool isPublic;
  final int downloadCount;
  final DateTime createdAt;
  final int cardCount;
  final int masteredCount;

  Deck({
    required this.uuid,
    required this.title,
    this.description,
    this.subject,
    this.level,
    this.isPublic = false,
    this.downloadCount = 0,
    required this.createdAt,
    this.cardCount = 0,
    this.masteredCount = 0,
  });
}
