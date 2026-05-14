import 'package:equatable/equatable.dart';
import '../../../domain/entities/leaderboard_entry.dart';

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();
  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}
class LeaderboardLoading extends LeaderboardState {}
class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntry> entries;
  const LeaderboardLoaded(this.entries);
  @override
  List<Object?> get props => [entries];
}
class LeaderboardError extends LeaderboardState {
  final String message;
  const LeaderboardError(this.message);
  @override
  List<Object?> get props => [message];
}
