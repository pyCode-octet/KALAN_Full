import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/badge_repository.dart';
import 'badge_event.dart';
import 'badge_state.dart';

class BadgeBloc extends Bloc<BadgeEvent, BadgeState> {
  final BadgeRepository _repository;

  BadgeBloc(this._repository) : super(BadgeInitial()) {
    on<LoadBadges>((event, emit) async {
      emit(BadgeLoading());
      try {
        final unlocked = await _repository.getUserBadges();
        final all = await _repository.getAllBadges();
        emit(BadgeLoaded(unlocked, all));
      } catch (e) {
        emit(BadgeError(e.toString()));
      }
    });

    on<UnlockBadge>((event, emit) async {
      try {
        await _repository.unlockBadge(event.badgeKey);
        add(LoadBadges());
      } catch (e) {
        emit(BadgeError(e.toString()));
      }
    });
  }
}
