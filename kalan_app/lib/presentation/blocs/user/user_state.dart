import 'package:equatable/equatable.dart';

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}
class UserLoading extends UserState {}
class UserLoaded extends UserState {
  final Map<String, dynamic> profile;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> badges;
  final bool isOnline;
  const UserLoaded(this.profile, this.stats, this.badges, {this.isOnline = true});
  @override
  List<Object?> get props => [profile, stats, badges, isOnline];
}
class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override
  List<Object?> get props => [message];
}
