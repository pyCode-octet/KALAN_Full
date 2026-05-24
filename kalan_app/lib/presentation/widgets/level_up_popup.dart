import 'package:flutter/material.dart';
import '../../services/celebration_coordinator.dart';
import 'tree_evolution.dart';
import 'confetti_widget.dart';

class LevelUpPopup {
  static void show(
    BuildContext context, {
    required int level,
    required String title,
    required String icon,
    required int pointsReward,
    required int flashcardsCount,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // Forcer l'interaction
      barrierLabel: 'level_up_popup',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 150),
          child: _LevelUpContent(
            level: level,
            title: title,
            icon: icon,
            pointsReward: pointsReward,
            flashcardsCount: flashcardsCount,
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return Stack(
          children: [
            // Confetti background
            const Positioned.fill(child: ConfettiWidget()),
            
            ScaleTransition(
              scale: curved,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelUpContent extends StatelessWidget {
  final int level;
  final String title;
  final String icon;
  final int pointsReward;
  final int flashcardsCount;

  const _LevelUpContent({
    required this.level,
    required this.title,
    required this.icon,
    required this.pointsReward,
    required this.flashcardsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D6A2D).withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'NOUVEAU NIVEAU ! 🏆',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D6A2D),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 30),
              
              // Animated level icon with TreeEvolution
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3DE),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2D6A2D), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A2D).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: TreeEvolution(stage: level, size: 100),
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'NIVEAU $level',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Félicitations ! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF777777),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu es passé au niveau $level !',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ton savoir grandit comme cet arbre. Continue comme ça, tu as déjà généré $flashcardsCount fiches de révision ! 📚✨',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555555),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              
              // Rewards row
              Row(
                children: [
                  _rewardItem('Cadeau', '+$pointsReward XP', Colors.orange),
                  const SizedBox(width: 12),
                  _rewardItem('Total Fiches', '$flashcardsCount', const Color(0xFF2D6A2D)),
                ],
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    CelebrationCoordinator.dismiss();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SUPER ! 🎉',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
