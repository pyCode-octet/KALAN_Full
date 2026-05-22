import 'package:flutter/material.dart';
import 'confetti_widget.dart';

/// Affiche un popup animé quand un badge est débloqué.
/// Appelé via BadgeUnlockPopup.show(context, ...)
class BadgeUnlockPopup {
  static void show(
    BuildContext context, {
    required String label,
    required String emoji,
    String? imagePath,
    required int color,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'badge_popup',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 150),
          child: _BadgePopupContent(
            label: label,
            emoji: emoji,
            imagePath: imagePath,
            color: Color(color),
          ),
        ),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return Stack(
          children: [
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

class _BadgePopupContent extends StatefulWidget {
  final String label;
  final String emoji;
  final String? imagePath;
  final Color color;

  const _BadgePopupContent({
    required this.label,
    required this.emoji,
    required this.color,
    this.imagePath,
  });

  @override
  State<_BadgePopupContent> createState() => _BadgePopupContentState();
}

class _BadgePopupContentState extends State<_BadgePopupContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Étiquette "Nouveau badge !"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: widget.color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Badge débloqué !',
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image du badge
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color, width: 3),
                    color: widget.color.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: widget.imagePath != null
                        ? Image.asset(
                            'assets/badges/${widget.imagePath}',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(widget.emoji, style: const TextStyle(fontSize: 54)),
                            ),
                          )
                        : Center(
                            child: Text(widget.emoji, style: const TextStyle(fontSize: 54)),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nom du badge
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Félicitations ! Tu as gagné ce badge.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF777777),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton OK
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Super ! 🎉',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
