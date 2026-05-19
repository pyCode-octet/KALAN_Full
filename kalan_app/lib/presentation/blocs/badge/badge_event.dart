import 'package:equatable/equatable.dart';

abstract class BadgeEvent extends Equatable {
  const BadgeEvent();
  @override
  List<Object?> get props => [];
}

class LoadBadges extends BadgeEvent {}
class UnlockBadge extends BadgeEvent {
  final String badgeKey;
  const UnlockBadge(this.badgeKey);
  @override
  List<Object?> get props => [badgeKey];
}

class CheckNewBadges extends BadgeEvent {}
