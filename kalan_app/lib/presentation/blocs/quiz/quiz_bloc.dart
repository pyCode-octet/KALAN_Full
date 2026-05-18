import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/quiz_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository _repository;
  final UserRepository _userRepository;

  QuizBloc(this._repository, this._userRepository) : super(QuizInitial()) {
    on<SubmitQuiz>((event, emit) async {
      emit(QuizSubmitting());
      try {
        await _repository.saveQuizResult(event.deckId, event.score, event.total, event.duration);
        
        // Ajouter des points : 10 points par bonne réponse
        if (event.score > 0) {
          await _userRepository.addPoints(event.score * 10);
        }
        
        emit(const QuizSubmitted(true));
      } catch (e) {
        emit(QuizError(e.toString()));
      }
    });
  }
}
