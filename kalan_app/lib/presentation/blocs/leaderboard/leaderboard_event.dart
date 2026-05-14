import 'package:equatable/equatable.dart';

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
