import 'package:equatable/equatable.dart';

abstract class QuizState extends Equatable {
  const QuizState();
  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}
class QuizSubmitting extends QuizState {}
class QuizSubmitted extends QuizState {
  final bool success;
  const QuizSubmitted(this.success);
  @override
  List<Object?> get props => [success];
}
class QuizError extends QuizState {
  final String message;
  const QuizError(this.message);
  @override
  List<Object?> get props => [message];
}
