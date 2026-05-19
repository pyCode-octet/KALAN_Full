import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalan_app/presentation/blocs/flashcard/flashcard_bloc.dart';
import 'package:kalan_app/presentation/blocs/flashcard/flashcard_event.dart';
import 'package:kalan_app/presentation/blocs/flashcard/flashcard_state.dart';
import '../../core/constants/app_colors.dart';
import 'quiz_screen.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final String deckTitle;
  final String deckUuid;
  const FlashcardStudyScreen({super.key, required this.deckTitle, required this.deckUuid});

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  Timer? _timer;
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    context.read<FlashcardBloc>().add(LoadFlashcards(widget.deckUuid));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 5;
      _showAnswer = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _showAnswer = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EA),
      body: SafeArea(
        child: BlocConsumer<FlashcardBloc, FlashcardState>(
          listener: (context, state) {
            if (state is FlashcardLoaded && state.cards.isNotEmpty && _timer == null) {
              _startTimer();
            }
          },
          builder: (context, state) {
            if (state is FlashcardLoading) return const Center(child: CircularProgressIndicator());
            if (state is FlashcardError) return Center(child: Text(state.message));
            if (state is FlashcardLoaded) {
              final allCards = state.cards;
              // Limit the study session to exactly 5 flashcards
              final cards = allCards.take(5).toList();
              if (cards.isEmpty) return const Center(child: Text('Aucune carte dans ce deck.'));
              
              return Column(
                children: [
                  _buildCustomTopBar(widget.deckTitle),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${_currentIndex + 1} sur ${cards.length}', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Pas de retournement manuel avant la fin des 5 secondes (le minuteur s'occupe de révéler la réponse).
                        // Après 5s (_showAnswer est true), on pourrait permettre de retourner la carte
                        // pour revoir la question, mais l'utilisateur a demandé de commenter cette partie pour l'instant.
                        /*
                        if (_showAnswer) {
                          setState(() => _showAnswer = false);
                        }
                        */
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return RotationYTransition(animation: animation, child: child);
                        },
                        child: _showAnswer 
                          ? _buildCardSide(cards[_currentIndex].answer, true) 
                          : _buildCardSide(cards[_currentIndex].question, false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_showAnswer) 
                    _buildFeedbackButtons(cards.length, cards[_currentIndex].uuid) 
                  else 
                    _buildFlipInstruction(),
                  const SizedBox(height: 32),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildCustomTopBar(String subject) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left chevron button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE8E4DA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Color(0xFF555555),
                size: 24,
              ),
            ),
          ),
          // Subject Title
          Expanded(
            child: Center(
              child: Text(
                subject,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ),
          // Timer or check
          _showAnswer
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF3DE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF2D6A2D),
                    size: 16,
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: _secondsRemaining / 5,
                        strokeWidth: 2,
                        backgroundColor: const Color(0xFFE8E4DA),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2D6A2D),
                        ),
                      ),
                    ),
                    Text(
                      '$_secondsRemaining',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D6A2D),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildCardSide(String text, bool isAnswer) {
    return Container(
      key: ValueKey(isAnswer),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isAnswer ? const Color(0xFFEAF3DE) : const Color(0xFFF4F2EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAnswer ? 'SOLUTION' : 'QUESTION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isAnswer ? const Color(0xFF2D6A2D) : Colors.grey.shade600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.onBackground,
              fontFamily: 'Plus Jakarta Sans',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipInstruction() {
    return Column(
      children: [
        const Text(
          "La réponse s'affiche dans...",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$_secondsRemaining secondes',
          style: const TextStyle(
            color: Color(0xFF2D6A2D),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackButtons(int total, String cardUuid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Red "Je ne savais pas" button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<FlashcardBloc>().add(UpdateReview(cardUuid, 1));
                    _nextCard(total);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEBEB),
                      border: Border.all(color: const Color(0xFFF3A9A9), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.close,
                          color: Color(0xFFC92A2A),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Je ne savais pas',
                          style: TextStyle(
                            color: Color(0xFFC92A2A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Green "Je savais" button
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<FlashcardBloc>().add(UpdateReview(cardUuid, 3));
                    _nextCard(total);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3DE),
                      border: Border.all(color: const Color(0xFFB7D98C), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check,
                          color: Color(0xFF2D6A2D),
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Je savais',
                          style: TextStyle(
                            color: Color(0xFF2D6A2D),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // "Plus tard" button
          GestureDetector(
            onTap: () => _nextCard(total),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F2EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Plus tard',
                  style: TextStyle(
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextCard(int total) {
    if (_currentIndex < total - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
      _startTimer();
    } else {
      _showTransitionDialog();
    }
  }

  void _showTransitionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFCF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: const [
            Text(
              '🏆',
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 12),
            Text(
              'Bien joué !',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
        content: const Text(
          'On va rafraîchir la mémoire et voir ta maîtrise du cours. On va te proposer des quiz maintenant.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF555555),
            height: 1.5,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Fermer le dialog
                  Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        deckUuid: widget.deckUuid,
                        deckTitle: widget.deckTitle,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A2D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Commencer le Quiz',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RotationYTransition extends AnimatedWidget {
  final Widget child;
  const RotationYTransition({super.key, required Animation<double> animation, required this.child}) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final rotation = animation.value * 3.14159;
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(rotation),
      alignment: Alignment.center,
      child: rotation > 1.5708 ? Transform(transform: Matrix4.identity()..rotateY(3.14159), alignment: Alignment.center, child: child) : child,
    );
  }
}
