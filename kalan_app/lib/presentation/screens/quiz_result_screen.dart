import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'quiz_screen.dart';
import 'home_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String? deckUuid;
  final String? deckTitle;

  const QuizResultScreen({
    super.key, 
    required this.score, 
    required this.total,
    this.deckUuid,
    this.deckTitle,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? score / total : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Terminé !', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150, height: 150,
                    child: CircularProgressIndicator(
                      value: percent.toDouble(),
                      strokeWidth: 12,
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Text('$score/$total', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 32),
              Text(
                percent >= 0.7 ? 'Excellent !' : 'Continue comme ça !',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  child: const Text('RETOUR À L\'ACCUEIL'),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(builder: (_) => QuizScreen(
                    deckUuid: deckUuid,
                    deckTitle: deckTitle ?? 'Quiz',
                  )),
                ),
                child: const Text('Rejouer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
