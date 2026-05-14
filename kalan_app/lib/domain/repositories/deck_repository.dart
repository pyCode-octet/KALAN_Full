import '../entities/deck.dart';

abstract class DeckRepository {
  Future<List<Deck>> getDecks();
  Future<List<Deck>> getPublicDecks();
  Future<void> createDeck(String title, String subject, String? level);
  Future<void> deleteDeck(String uuid);
  Future<void> togglePublic(String uuid);
}
