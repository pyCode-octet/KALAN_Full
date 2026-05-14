import 'package:equatable/equatable.dart';

abstract class FlashcardEvent extends Equatable {
  const FlashcardEvent();
  @override
  List<Object?> get props => [];
}

class LoadFlashcards extends FlashcardEvent {
  final String deckUuid;
  const LoadFlashcards(this.deckUuid);
  @override
  List<Object?> get props => [deckUuid];
}

class AddFlashcard extends FlashcardEvent {
  final String deckUuid;
  final String question;
  final String answer;
  const AddFlashcard(this.deckUuid, this.question, this.answer);
  @override
  List<Object?> get props => [deckUuid, question, answer];
}

class UpdateReview extends FlashcardEvent {
  final String cardUuid;
  final int difficulty;
  const UpdateReview(this.cardUuid, this.difficulty);
  @override
  List<Object?> get props => [cardUuid, difficulty];
}
