import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/leaderboard_repository.dart';
import '../../../domain/entities/leaderboard_entry.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRepository _repository;
  StreamSubscription? _subscription;

  LeaderboardBloc(this._repository) : super(LeaderboardInitial()) {
    on<LoadLeaderboard>((event, emit) async {
      emit(LeaderboardLoading());
      
      try {
        // Charger les données initiales
        final entries = await _repository.getLeaderboard(scope: event.scope);
        if (!emit.isDone) {
          emit(LeaderboardLoaded(entries));
        }

        // Écouter les mises à jour en temps réel
        await emit.forEach<List<LeaderboardEntry>>(
          _repository.watchLeaderboard(scope: event.scope),
          onData: (entries) {
            return LeaderboardLoaded(entries);
          },
          onError: (e, stackTrace) {
            return LeaderboardError(e.toString());
          },
        );
      } catch (e) {
        if (!emit.isDone) {
          emit(LeaderboardError(e.toString()));
        }
      }
    });

    on<OnLeaderboardUpdate>((event, emit) {
      emit(LeaderboardLoaded(event.entries));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
