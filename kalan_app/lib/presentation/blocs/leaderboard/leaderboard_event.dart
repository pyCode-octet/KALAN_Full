import 'package:equatable/equatable.dart';
import 'package:kalan_app/domain/entities/leaderboard_entry.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeaderboard extends LeaderboardEvent {
  final String scope;
  const LoadLeaderboard({this.scope = 'national'});
  @override
  List<Object?> get props => [scope];
}

class OnLeaderboardUpdate extends LeaderboardEvent {
  final List<LeaderboardEntry> entries;
  const OnLeaderboardUpdate(this.entries);
  @override
  List<Object?> get props => [entries];
}
