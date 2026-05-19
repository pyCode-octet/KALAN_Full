import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/utils/level_utils.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import 'flashcard_study_screen.dart';
import 'deck_list_screen.dart';
import 'badges_screen.dart';
import 'notification_screen.dart';
import '../../data/local/database_helper.dart';
import 'roadmap_screen.dart';
import '../blocs/notification/notification_bloc.dart';
import '../blocs/notification/notification_state.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.fredokaTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                      _buildLevelCard(context, levelInfo, points),
                      _buildStatsGrid(context, stats, profile),
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, ${profile['pseudo'] ?? 'Ami'} 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              const Text(
                'Prêt à apprendre aujourd\'hui ?',
                style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
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

  Widget _buildLevelCard(BuildContext context, LevelInfo levelInfo, int points) {
    final progress = (points / levelInfo.nextLevelPoints).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RoadmapScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ton niveau', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      levelInfo.title.toUpperCase(),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: const Color(0xFF2D6A2D), borderRadius: BorderRadius.circular(4)),
                      child: const Icon(Icons.star, color: Colors.white, size: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('Niveau ${levelInfo.level}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 7,
                      width: double.infinity,
                      decoration: BoxDecoration(color: const Color(0xFFE8E4DA), borderRadius: BorderRadius.circular(10)),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 7,
                        decoration: BoxDecoration(color: const Color(0xFF2D6A2D), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: Color(0xFFEAF3DE), shape: BoxShape.circle),
                child: const Icon(Icons.park, size: 40, color: Color(0xFF2D6A2D)),
              ),
              const SizedBox(height: 6),
              Text(
                '$points / ${levelInfo.nextLevelPoints} XP',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2D6A2D)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats, Map<String, dynamic> profile) {
    final deckCount = stats['deckCount'] ?? 0;
    final quizCount = stats['quizCount'] ?? 0;
    final avgScore = (stats['avgScore'] * 100).toInt();
    final points = profile['points'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tes statistiques', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  // Navigation vers profil (HomeScreen gère ça via IndexedStack normalement, 
                  // mais on peut forcer le refresh ou le changement d'index si on avait accès au controller)
                },
                child: const Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF2D6A2D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(Icons.layers, deckCount.toString(), 'Fiches', const Color(0xFF378ADD)),
              const SizedBox(width: 7),
              _buildStatItem(Icons.check_box, quizCount.toString(), 'Quiz', const Color(0xFFE07B39)),
              const SizedBox(width: 7),
              _buildStatItem(Icons.trending_up, '$avgScore%', 'Moyenne', const Color(0xFF2D6A2D)),
              const SizedBox(width: 7),
              _buildStatItem(Icons.stars, points.toString(), 'Points', const Color(0xFFBA7517)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<Map<String, dynamic>> userBadges) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tes badges', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
                child: const Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF2D6A2D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 85,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getAllBadges(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final allBadges = snapshot.data!;
                final unlockedKeys = userBadges.map((b) => b['badge_key']).toSet();
                final earnedBadges = allBadges.where((b) => unlockedKeys.contains(b['id'])).toList();

                if (earnedBadges.isEmpty) return const Center(child: Text('Aucun badge débloqué', style: TextStyle(fontSize: 12, color: Colors.grey)));

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: earnedBadges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final badge = earnedBadges[index];
                    final color = Color(badge['color'] as int);
                    return Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(badge['emoji'] ?? '🏆', style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          badge['label'],
                          style: const TextStyle(fontSize: 10, color: Color(0xFF555555), fontWeight: FontWeight.w500),
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
              const Text('Activités récentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeckListScreen())),
                child: const Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF2D6A2D), fontWeight: FontWeight.bold)),
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
                border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentDecks.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withOpacity(0.05)),
                itemBuilder: (context, index) {
                  final deck = recentDecks[index];
                  final subject = deck['subject'] ?? 'Général';
                  final dateStr = deck['created_at'] ?? DateTime.now().toIso8601String();
                  final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                  final score = deck['lastScore'];
                  final cardCount = deck['cardCount'] ?? 0;

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FlashcardStudyScreen(deckTitle: deck['title'], deckUuid: deck['uuid']),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getSubjectColor(subject).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.book, size: 20, color: _getSubjectColor(subject)),
                    ),
                    title: Text(
                      deck['title'],
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    subtitle: Text(
                      score != null ? 'Dernier score : $score%' : '$cardCount cartes créées',
                      style: TextStyle(fontSize: 12, color: score != null ? _getSubjectColor(subject) : const Color(0xFF999999)),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatDate(date), style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 14, color: Color(0xFFCCCCCC)),
                      ],
                    ),
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
      case 'informatique':
        return const Color(0xFF009688);
      case 'autre':
        return const Color(0xFF757575);
      default:
        return const Color(0xFF2D6A2D);
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
