import '../entities/flashcard.dart';

abstract class FlashcardRepository {
  Future<List<Flashcard>> getFlashcardsByDeck(String deckUuid);
  Future<void> createFlashcard(String deckUuid, String question, String answer);
  Future<void> deleteFlashcard(String uuid);
  Future<void> updateFlashcardReview(String uuid, int difficulty);
}
