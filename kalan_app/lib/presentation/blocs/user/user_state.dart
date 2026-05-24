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
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> searchResults;
  final bool isOnline;

  const UserLoaded(
    this.profile, 
    this.stats, 
    this.badges, {
    this.friends = const [],
    this.searchResults = const [],
    this.isOnline = true,
  });

  UserLoaded copyWith({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? badges,
    List<Map<String, dynamic>>? friends,
    List<Map<String, dynamic>>? searchResults,
    bool? isOnline,
  }) {
    return UserLoaded(
      profile ?? this.profile,
      stats ?? this.stats,
      badges ?? this.badges,
      friends: friends ?? this.friends,
      searchResults: searchResults ?? this.searchResults,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [profile, stats, badges, friends, searchResults, isOnline];
}
class UserError extends UserState {
  final String message;
  const UserError(this.message);
  @override
  List<Object?> get props => [message];
}
