import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';
import '../../core/constants/app_colors.dart';
import '../../core/utils/level_utils.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import 'quiz_screen.dart';
import '../widgets/tree_evolution.dart';
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
    final earnedPoints = score * 10;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  int points = earnedPoints;
                  bool isLoaded = false;
                  
                  if (state is UserLoaded) {
                    points = state.profile['points'] as int? ?? 0;
                    isLoaded = true;
                  }

                  final previousPoints = max(0, points - earnedPoints);
                  final prevLevelInfo = LevelUtils.getLevelInfo(previousPoints);
                  final currentLevelInfo = LevelUtils.getLevelInfo(points);
                  final leveledUp = prevLevelInfo.level < currentLevelInfo.level;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Bravo !',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tu as obtenu',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(percent * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        percent >= 0.8 
                            ? 'Tu maîtrises bien ce chapitre 💪' 
                            : percent >= 0.5 
                                ? 'C\'est un bon début ! 👍' 
                                : 'Continue de t\'entraîner ! 🌱',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Stats row from HTML design
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3DE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  const Text('Bonnes réponses', style: TextStyle(fontSize: 11, color: Color(0xFF3B6D11), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('$score', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF2D6A2D))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCEBEB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  const Text('Mauvaises réponses', style: TextStyle(fontSize: 11, color: Color(0xFFA32D2D), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('${total - score}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFE24B4A))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Reward XP tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('👑 ', style: TextStyle(fontSize: 18)),
                            Text(
                              '+$earnedPoints XP',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF8B7500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Level progression card
                      if (isLoaded) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF0EBE0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      TreeEvolution(stage: currentLevelInfo.level, size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rang : ${currentLevelInfo.title}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: Color(0xFF111111),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Niveau ${currentLevelInfo.level}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: (points / currentLevelInfo.nextLevelPoints).clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFF0EBE0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$points / ${currentLevelInfo.nextLevelPoints} XP',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Level Up celebratory card
                      if (leveledUp) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFF7C2), Color(0xFFFFEFA6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFFFD700), width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              const Text(
                                'MONTÉE DE NIVEAU !',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF8B6508),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Félicitations, tu es passé au niveau ${currentLevelInfo.level} :\n${currentLevelInfo.title} ! 🌱',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5E491A),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Actions
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context, 
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'RETOUR À L\'ACCUEIL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context, 
                          MaterialPageRoute(builder: (_) => QuizScreen(
                            deckUuid: deckUuid,
                            deckTitle: deckTitle ?? 'Quiz',
                          )),
                        ),
                        child: const Text(
                          'Rejouer le Quiz',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
