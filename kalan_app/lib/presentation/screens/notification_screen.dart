import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;

  final List<Map<String, dynamic>> _mockNotifications = [
    {
      'id': '1',
      'type': 'review',
      'title': 'C\'est l\'heure de réviser !',
      'message': 'Tes fiches de SVT t\'attendent pour une session rapide.',
      'time': 'Il y a 10 min',
      'isRead': false,
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF2D6A2D),
    },
    {
      'id': '2',
      'type': 'badge',
      'title': 'Nouveau Badge Débloqué ! 🏆',
      'message': 'Bravo ! Tu as obtenu le badge "L\'Apprenti Chercheur".',
      'time': 'Il y a 2 heures',
      'isRead': false,
      'icon': Icons.emoji_events_rounded,
      'color': const Color(0xFF854F0B),
    },
    {
      'id': '3',
      'type': 'leaderboard',
      'title': 'Progression au classement',
      'message': 'Tu es maintenant 5ème de ta classe ! Continue tes efforts.',
      'time': 'Hier',
      'isRead': true,
      'icon': Icons.trending_up_rounded,
      'color': const Color(0xFF185FA5),
    },
    {
      'id': '4',
      'type': 'social',
      'title': 'Nouvelle fiche partagée',
      'message': 'Moussa a publié un nouveau deck "Histoire du Burkina".',
      'time': 'Hier',
      'isRead': true,
      'icon': Icons.share_rounded,
      'color': const Color(0xFFBE123C),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      body: Stack(
        children: [
          // Arrière-plan avec filigranes animés
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AfricanWatermarkPainter(progress: _animationController.value),
                );
              },
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: _mockNotifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A4D2E)),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Notifications',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A4D2E),
                ),
              ),
            ],
          ),
          if (_mockNotifications.any((n) => !n['isRead']))
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _mockNotifications) {
                    n['isRead'] = true;
                  }
                });
              },
              child: Text(
                'Tout lire',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _mockNotifications.length,
      itemBuilder: (context, index) {
        final notification = _mockNotifications[index];
        return _buildNotificationItem(notification);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final bool isRead = notification['isRead'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white.withOpacity(0.7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead ? const Color(0xFFF0EBE0) : AppColors.primary.withOpacity(0.1),
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (!isRead)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFE24B4A),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(notification['icon'], color: notification['color'], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: const Color(0xFF666666),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['time'],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFAAAAAA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7F0),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'Tout est calme ici',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A4D2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviens plus tard pour tes rappels.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class AfricanWatermarkPainter extends CustomPainter {
  final double progress;
  AfricanWatermarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double w = size.width;
    final double h = size.height;

    // Animation de flottement
    double offset = math.sin(progress * 2 * math.pi) * 15;

    // Symbole 1 (Haut Gauche)
    _drawAdinkraGyeNyame(canvas, paint, w * 0.15, h * 0.15 + offset, 40);

    // Symbole 2 (Bas Droite)
    _drawAdinkraGyeNyame(canvas, paint, w * 0.85, h * 0.8 + offset, 60);

    // Symbole 3 (Milieu Gauche)
    _drawPattern(canvas, paint, w * 0.1, h * 0.5 - offset, 30);

    // Symbole 4 (Haut Droite)
    _drawPattern(canvas, paint, w * 0.8, h * 0.3 - offset, 25);
  }

  void _drawAdinkraGyeNyame(Canvas canvas, Paint paint, double x, double y, double size) {
    final path = Path();
    // Dessin simplifié d'un motif de type Gye Nyame
    path.moveTo(x, y - size);
    path.quadraticBezierTo(x + size, y, x, y + size);
    path.quadraticBezierTo(x - size, y, x, y - size);
    path.moveTo(x - size * 0.5, y);
    path.lineTo(x + size * 0.5, y);
    canvas.drawPath(path, paint);
  }

  void _drawPattern(Canvas canvas, Paint paint, double x, double y, double size) {
    // Motif géométrique type Bogolan
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x + i * 10, y + i * 10), width: size, height: size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
