import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_badge.dart';

abstract class BadgeState extends Equatable {
  const BadgeState();
  @override
  List<Object?> get props => [];
}

class BadgeInitial extends BadgeState {}
class BadgeLoading extends BadgeState {}
class BadgeLoaded extends BadgeState {
  final List<UserBadge> unlockedBadges;
  const BadgeLoaded(this.unlockedBadges);
  @override
  List<Object?> get props => [unlockedBadges];
}
class BadgeError extends BadgeState {
  final String message;
  const BadgeError(this.message);
  @override
  List<Object?> get props => [message];
}
