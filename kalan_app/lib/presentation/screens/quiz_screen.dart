import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/flashcard.dart';
import '../blocs/flashcard/flashcard_bloc.dart';
import '../blocs/flashcard/flashcard_event.dart';
import '../blocs/flashcard/flashcard_state.dart';
import '../blocs/quiz/quiz_bloc.dart';
import '../blocs/quiz/quiz_event.dart';
import '../blocs/quiz/quiz_state.dart';
import 'quiz_result_screen.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  final String? deckUuid;
  final String deckTitle;
  const QuizScreen({super.key, this.deckUuid, this.deckTitle = 'Quiz'});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  final DateTime _startTime = DateTime.now();
  List<Map<String, dynamic>> _quizQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.deckUuid != null) {
      context.read<FlashcardBloc>().add(LoadFlashcards(widget.deckUuid!));
    }
  }

  void _generateQuiz(List<Flashcard> cards) {
    if (cards.isEmpty) return;
    
    final List<Map<String, dynamic>> questions = [];

    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      final List<String> options = [card.answer];
      
      // Add distractors from other cards
      final otherAnswers = cards.where((c) => c.uuid != card.uuid).map((c) => c.answer).toList();
      otherAnswers.shuffle();
      
      options.addAll(otherAnswers.take(3));

      // If we don't have enough distractors, add generic ones
      while (options.length < 4) {
        options.add('Réponse bidon ${options.length}');
      }

      options.shuffle();
      
      questions.add({
        'q': card.question,
        'options': options,
        'a': options.indexOf(card.answer),
      });
    }

    setState(() {
      _quizQuestions = questions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FlashcardBloc, FlashcardState>(
      listener: (context, state) {
        if (state is FlashcardLoaded) {
          _generateQuiz(state.cards);
        } else if (state is FlashcardError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocListener<QuizBloc, QuizState>(
        listener: (context, state) {
          if (state is QuizSubmitted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => QuizResultScreen(
                  score: _score, 
                  total: _quizQuestions.length,
                  deckUuid: widget.deckUuid,
                  deckTitle: widget.deckTitle,
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(widget.deckTitle),
            leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ),
          body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _quizQuestions.isEmpty
              ? _buildEmptyState()
              : _buildQuizBody(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          const Text('Pas assez de flashcards pour un quiz'),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
        ],
      ),
    );
  }

  Widget _buildQuizBody() {
    final question = _quizQuestions[_currentQuestionIndex];

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _quizQuestions.length,
            minHeight: 8,
            backgroundColor: Colors.white,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 40),
          Text(
            'Question ${_currentQuestionIndex + 1}/${_quizQuestions.length}',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            question['q'],
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 40),
          Expanded(
            child: ListView.builder(
              itemCount: question['options'].length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.onBackground,
                      side: BorderSide(color: Colors.grey.shade200),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(question['options'][index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(int index) {
    if (index == _quizQuestions[_currentQuestionIndex]['a']) {
      _score++;
    }

    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      final duration = DateTime.now().difference(_startTime).inSeconds;
      context.read<QuizBloc>().add(SubmitQuiz(
        deckId: widget.deckUuid,
        score: _score,
        total: _quizQuestions.length,
        duration: duration,
      ));
    }
  }
}
