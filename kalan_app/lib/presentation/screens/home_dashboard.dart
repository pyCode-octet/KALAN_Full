import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/utils/level_utils.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import '../widgets/tree_evolution.dart';
import 'flashcard_study_screen.dart';
import 'badges_screen.dart';
import 'notification_screen.dart';
import '../../data/local/database_helper.dart';
import 'roadmap_screen.dart';
import '../blocs/notification/notification_bloc.dart';
import '../blocs/notification/notification_state.dart';
import 'library_screen.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F2EA),
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading) return const Center(child: CircularProgressIndicator());
            if (state is UserError) return Center(child: Text(state.message));
            if (state is UserLoaded) {
              final profile = state.profile;
              final stats = state.stats;
              final userBadges = state.badges;
              final points = profile['points'] as int? ?? 0;
              final levelInfo = LevelUtils.getLevelInfo(points);
              final recentDecks = (stats['recentDecks'] as List<dynamic>?) ?? [];

              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, profile),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Opacity(
                                opacity: 0.0,
                                child: IgnorePointer(
                                  child: _buildFloatingBanner(context),
                                ),
                              ),
                              _buildIntegratedLevelBlock(context, levelInfo, points),
                            ],
                          ),
                          _buildFloatingBanner(context),
                        ],
                      ),
                      _buildDynamicSubjectsGrid(context, recentDecks),
                      if (userBadges.isNotEmpty) _buildBadgesSection(context, userBadges),
                      _buildRecentActivitySection(context, recentDecks),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, ${profile['pseudo'] ?? 'Ami'} 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          Row(
            children: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, notificationState) {
                  final bool hasUnread = notificationState is NotificationLoaded &&
                      notificationState.notifications.any((n) => n['is_read'] == 0);
                  
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          );
                        },
                        icon: const Icon(Icons.notifications_none_rounded, size: 26, color: Color(0xFF1A1A1A)),
                      ),
                      if (hasUnread)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE24B4A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildAvatar(profile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> profile) {
    final avatarId = profile['avatar_id'];
    final avatarUrl = profile['avatar_url'];

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFE8C87A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.startsWith('http')
            ? Image.network(avatarUrl, fit: BoxFit.cover)
            : Image.asset(
                'assets/avatars/avatar${avatarId ?? 1}.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.person, color: Colors.white)),
              ),
      ),
    );
  }

  Widget _buildFloatingBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5C14), Color(0xFF3B6D11)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D5C14).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kalan : Ta quête du savoir !',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                SizedBox(height: 4),
                Text(
                  '"Chaque jour est une chance de devenir plus sage." 🌟',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegratedLevelBlock(BuildContext context, LevelInfo levelInfo, int points) {
    final progress = (points / levelInfo.nextLevelPoints).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoadmapScreen()),
        );
      },
      child: Transform.translate(
        offset: const Offset(0, -25),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.fromLTRB(20, 45, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8)),
            ],
            border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TON STATUT',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w700, letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          levelInfo.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFFFAC775), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.star, color: Color(0xFFBA7517), size: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(84, 84),
                          painter: OuroborosPainter(progress: progress, color: const Color(0xFF2D5C14)),
                        ),
                        // Mascot image or fallback TreeEvolution inside the circle
                        ClipOval(
                          child: Image.asset(
                            'assets/badges/humanites/ideogram-v3.0_BADGE_Pousse_kalan.jpg',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return TreeEvolution(stage: levelInfo.level, size: 42);
                            },
                          ),
                        ),
                        // Level number badge
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2D5C14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'NIV. ${levelInfo.level}',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$points / ${levelInfo.nextLevelPoints} XP',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF2D5C14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicSubjectsGrid(BuildContext context, List<dynamic> recentDecks) {
    // Collect stats from recentDecks or could be passed from state.stats if available
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tes matières', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                child: const Text('Voir tout', style: TextStyle(fontSize: 11, color: Color(0xFF2D5C14), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseHelper.instance.getAllSubjects(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 100);
              final subjects = snapshot.data!.take(4).toList(); // Take first 4 for grid
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final s = subjects[index];
                  final color = Color(s['color'] as int);
                  return _buildCategoryItem(s['label'], 'Découvrir', Icons.school_rounded, color.withValues(alpha: 0.1), color);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, String count, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                Text(count, style: const TextStyle(fontSize: 9, color: Color(0xFFAAAAAA))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<Map<String, dynamic>> userBadges) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tes badges', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
                child: const Text('Voir tout', style: TextStyle(fontSize: 11, color: Color(0xFF2D5C14), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getAllBadges(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final allBadges = snapshot.data!;
                final unlockedKeys = userBadges.map((b) => b['badge_key']).toSet();
                final earnedBadges = allBadges.where((b) => unlockedKeys.contains(b['id'])).toList();

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: earnedBadges.length.clamp(0, 6),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final badge = earnedBadges[index];
                    final color = Color(badge['color'] as int);
                    final imagePath = badge['image_path'] as String?;
                    return Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: ClipOval(
                            child: imagePath != null
                                ? Image.asset(
                                    'assets/badges/$imagePath',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(badge['emoji'] ?? '🏆', style: const TextStyle(fontSize: 20)),
                                  )
                                : Text(badge['emoji'] ?? '🏆', style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badge['label'],
                          style: const TextStyle(fontSize: 9, color: Color(0xFF555555), fontWeight: FontWeight.w600),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, List<dynamic> recentDecks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activités récentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen())),
                child: const Text('Voir tout', style: TextStyle(fontSize: 11, color: Color(0xFF2D5C14), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentDecks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aucune activité récente', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.04), width: 0.5),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentDecks.length.clamp(0, 4),
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withValues(alpha: 0.03)),
                itemBuilder: (context, index) {
                  final deck = recentDecks[index];
                  final subject = deck['subject'] ?? 'Général';
                  final score = deck['lastScore'];
                  final dateStr = deck['created_at'] ?? DateTime.now().toIso8601String();
                  final date = DateTime.tryParse(dateStr) ?? DateTime.now();

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlashcardStudyScreen(deckTitle: deck['title'], deckUuid: deck['uuid']),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getSubjectColor(subject).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.book_rounded, size: 18, color: _getSubjectColor(subject)),
                    ),
                    title: Text(
                      deck['title'],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          score != null ? 'Score : $score%' : 'En cours',
                          style: TextStyle(fontSize: 11, color: score != null ? _getSubjectColor(subject) : const Color(0xFF999999), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(date),
                          style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCCCCCC)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathématiques':
      case 'maths':
        return const Color(0xFF185FA5);
      case 'svt':
        return const Color(0xFF2D6A2D);
      case 'physique-chimie':
        return const Color(0xFF6A2D9F);
      case 'anglais':
        return const Color(0xFFE07B39);
      case 'français':
        return const Color(0xFFB00020);
      case 'histoire-géo':
        return const Color(0xFF854F0B);
      default:
        return const Color(0xFF2196F3); // Bleu pour Autre
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    return DateFormat('dd/MM').format(date);
  }
}

class OuroborosPainter extends CustomPainter {
  final double progress;
  final Color color;

  OuroborosPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final strokeWidth = 7.0;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFF0EEE9)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
    
    // Serpent head simplified
    final headAngle = -math.pi / 2 + (2 * math.pi * progress);
    final headOffset = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );
    
    final headPaint = Paint()..color = color;
    canvas.drawCircle(headOffset, 4, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
