import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/leaderboard_repository.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRepository _repository;

  LeaderboardBloc(this._repository) : super(LeaderboardInitial()) {
    on<LoadLeaderboard>((event, emit) async {
      emit(LeaderboardLoading());
      try {
        final entries = await _repository.getLeaderboard(scope: event.scope);
        emit(LeaderboardLoaded(entries));
      } catch (e) {
        debugPrint('Erreur chargement classement : $e');
        emit(const LeaderboardError('Impossible de charger le classement. Réessaie.'));
      }
    });

    on<OnLeaderboardUpdate>((event, emit) {
      emit(LeaderboardLoaded(event.entries));
    });
  }
}
