import 'package:equatable/equatable.dart';

abstract class DeckEvent extends Equatable {
  const DeckEvent();
  @override
  List<Object?> get props => [];
}

class LoadDecks extends DeckEvent {
  const LoadDecks();
}

class CreateDeck extends DeckEvent {
  final String title;
  final String subject;
  final String? level;
  const CreateDeck(this.title, this.subject, this.level);
  @override
  List<Object?> get props => [title, subject, level];
}

class DeleteDeck extends DeckEvent {
  final String uuid;
  const DeleteDeck(this.uuid);
  @override
  List<Object?> get props => [uuid];
}

class ToggleDeckPublic extends DeckEvent {
  final String uuid;
  const ToggleDeckPublic(this.uuid);
  @override
  List<Object?> get props => [uuid];
}
