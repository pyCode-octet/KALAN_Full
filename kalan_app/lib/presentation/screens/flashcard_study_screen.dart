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

  @override
  void initState() {
    super.initState();
    context.read<FlashcardBloc>().add(LoadFlashcards(widget.deckUuid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.deckTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.quiz_rounded),
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  deckUuid: widget.deckUuid,
                  deckTitle: widget.deckTitle,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<FlashcardBloc, FlashcardState>(
        builder: (context, state) {
          if (state is FlashcardLoading) return const Center(child: CircularProgressIndicator());
          if (state is FlashcardError) return Center(child: Text(state.message));
          if (state is FlashcardLoaded) {
            final cards = state.cards;
            if (cards.isEmpty) return const Center(child: Text('Aucune carte dans ce deck.'));
            
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('${_currentIndex + 1}/${cards.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showAnswer = !_showAnswer),
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
                SizedBox(height: 40),
                if (_showAnswer) _buildFeedbackButtons(cards.length, cards[_currentIndex].uuid) else _buildFlipInstruction(),
                SizedBox(height: 40),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCardSide(String text, bool isAnswer) {
    return Container(
      key: ValueKey(isAnswer),
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        border: Border.all(color: isAnswer ? AppColors.secondary : AppColors.primary, width: 2),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isAnswer ? 'RÉPONSE' : 'QUESTION',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
          ),
          SizedBox(height: 24),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.onBackground),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipInstruction() {
    return Text(
      'Tapez sur la carte pour voir la réponse',
      style: TextStyle(color: Colors.grey, fontSize: 14),
    );
  }

  Widget _buildFeedbackButtons(int total, String cardUuid) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _feedbackButton('Difficile', AppColors.error, () {
            context.read<FlashcardBloc>().add(UpdateReview(cardUuid, 1));
            _nextCard(total);
          }),
          _feedbackButton('Moyen', AppColors.secondary, () {
            context.read<FlashcardBloc>().add(UpdateReview(cardUuid, 2));
            _nextCard(total);
          }),
          _feedbackButton('Facile', AppColors.primary, () {
            context.read<FlashcardBloc>().add(UpdateReview(cardUuid, 3));
            _nextCard(total);
          }),
        ],
      ),
    );
  }

  Widget _feedbackButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16),
        minimumSize: Size(90, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _nextCard(int total) {
    if (_currentIndex < total - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      Navigator.pop(context);
    }
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
