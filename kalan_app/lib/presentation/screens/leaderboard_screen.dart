import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/leaderboard/leaderboard_bloc.dart';
import '../blocs/leaderboard/leaderboard_event.dart';
import '../blocs/leaderboard/leaderboard_state.dart';
import '../../data/remote/supabase_service.dart';
import '../../services/connectivity_service.dart';
import 'roadmap_screen.dart';
import 'versus_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _currentScope = 'national';
  bool _isOnline = true;
  final bool _checkingConnection = false; // Plus besoin de bloquer au démarrage, le Bloc gère le Loading

  ImageProvider _getAvatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return const AssetImage('assets/avatars/avatar1.png');
    }
    if (avatar.startsWith('assets/')) {
      return AssetImage(avatar);
    }
    return NetworkImage(avatar);
  }

  @override
  void initState() {
    super.initState();
    // Chargement initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardBloc>().add(LoadLeaderboard(scope: _currentScope));
    });
  }

  // La connexion est gérée par le Bloc et le Repository, 
  // on garde une version simplifiée pour l'affichage du mode offline initial.
  Future<void> _checkConnectionAndRefresh() async {
    final online = await ConnectivityService().isOnline();
    setState(() => _isOnline = online);
    if (online) {
      context.read<LeaderboardBloc>().add(LoadLeaderboard(scope: _currentScope));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      appBar: AppBar(
        title: const Text('Classement', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D5C14))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoadmapScreen())),
            icon: const Icon(Icons.map_rounded, color: Color(0xFF2D5C14)),
            tooltip: 'Mon Parcours',
          ),
        ],
      ),
      body: _checkingConnection
          ? const Center(child: CircularProgressIndicator())
          : !_isOnline
              ? _buildOfflineWidget()
              : BlocBuilder<LeaderboardBloc, LeaderboardState>(
                  builder: (context, state) {
                    if (state is LeaderboardLoading) return const Center(child: CircularProgressIndicator());
                    if (state is LeaderboardError) return Center(child: Text(state.message));
                    if (state is LeaderboardLoaded) {
                      if (state.entries.isEmpty) {
                        return Column(
                          children: [
                            _buildTabs(),
                            const Expanded(
                              child: Center(
                                child: Text('Aucune donnée disponible.'),
                              ),
                            ),
                          ],
                        );
                      }

                      final topThree = state.entries.take(3).toList();
                      final remaining = state.entries.skip(3).take(7).toList(); // Ranks 4-10
                      
                      final currentUserId = SupabaseService.currentUser?.id;
                      final userIndex = state.entries.indexWhere((e) => e.userId == currentUserId);
                      final hasMyEntry = userIndex != -1;
                      final myEntry = hasMyEntry ? state.entries[userIndex] : null;
                      final myRank = hasMyEntry ? userIndex + 1 : null;

                      final tickerMessage = myRank != null
                          ? 'Félicitations ! Tu es au $myRank${myRank == 1 ? 'er' : 'ème'} rang mondial avec ${myEntry!.points} XP • Continue de progresser ! 🚀'
                          : 'Continue de progresser pour faire partie du classement et gagner plus d\'XP ! 🚀';

                      return Column(
                        children: [
                          _buildTabs(),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildTopThree(topThree),
                                  const SizedBox(height: 10),
                                  MarqueeTicker(
                                    text: tickerMessage,
                                  ),
                                  const SizedBox(height: 15),
                                  _buildCompactList(remaining),
                                  const SizedBox(height: 20),
                                  _buildVersusBlock(context),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
    );
  }

  Widget _buildOfflineWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D5C14).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFF2D5C14),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connexion internet requise',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2A1A08),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pour afficher ton rang et le classement des 10 meilleurs élèves en temps réel sur Supabase, tu dois être connecté à Internet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _checkConnectionAndRefresh,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5C14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: const Color(0xFF2D5C14).withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _tabItem('Semaine', 'weekly'),
          _tabItem('Mois', 'monthly'),
          _tabItem('National', 'national'),
        ],
      ),
    );
  }

  Widget _tabItem(String label, String scope) {
    final active = _currentScope == scope;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentScope = scope);
          context.read<LeaderboardBloc>().add(LoadLeaderboard(scope: scope));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: active ? const Color(0xFF2D5C14) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopThree(List<dynamic> topThree) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length >= 2) _podiumUser(topThree[1], 2, 60),
          const SizedBox(width: 12),
          if (topThree.isNotEmpty) _podiumUser(topThree[0], 1, 80, isFirst: true),
          const SizedBox(width: 12),
          if (topThree.length >= 3) _podiumUser(topThree[2], 3, 60),
        ],
      ),
    );
  }

  Widget _podiumUser(dynamic entry, int rank, double size, {bool isFirst = false}) {
    return Column(
      children: [
        if (isFirst) const Text('👑', style: TextStyle(fontSize: 22)),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: rank == 1 ? const Color(0xFFF5C842) : (rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32)),
              width: 3,
            ),
          ),
          child: ClipOval(child: Image(image: _getAvatarImage(entry.avatar), fit: BoxFit.cover)),
        ),
        const SizedBox(height: 6),
        Text(entry.pseudo, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        Text('${entry.points} XP', style: const TextStyle(color: Color(0xFF5A8A20), fontWeight: FontWeight.w700, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          height: isFirst ? 60 : (rank == 2 ? 45 : 35),
          width: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: rank == 1 
                ? [const Color(0xFFF5C842), const Color(0xFFE8A820)]
                : (rank == 2 ? [const Color(0xFFD0D0D0), const Color(0xFFB0B0B0)] : [const Color(0xFFCD9060), const Color(0xFFA06040)]),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
        ),
      ],
    );
  }

  Widget _buildCompactList(List<dynamic> remaining) {
    final currentUserId = SupabaseService.currentUser?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10, right: 10, bottom: 6),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('RANG', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800))),
                Expanded(child: Text('UTILISATEUR', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800))),
                Text('POINTS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: remaining.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final entry = remaining[index];
                final rank = index + 4;
                final isMe = entry.userId == currentUserId;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  color: isMe ? const Color(0xFFEDF5E0) : Colors.transparent,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w800, color: isMe ? const Color(0xFF2D5C14) : Colors.grey, fontSize: 13)),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isMe ? const Color(0xFF2D5C14) : Colors.transparent, width: 1)),
                        child: ClipOval(child: Image(image: _getAvatarImage(entry.avatar), fit: BoxFit.cover)),
                      ),
                      Expanded(
                        child: Text(
                          entry.pseudo + (isMe ? ' (Toi)' : ''),
                          style: TextStyle(fontWeight: FontWeight.w700, color: isMe ? const Color(0xFF2D5C14) : const Color(0xFF2A1A08), fontSize: 13),
                        ),
                      ),
                      Text('${entry.points} XP', style: TextStyle(fontWeight: FontWeight.w800, color: isMe ? const Color(0xFF2D5C14) : const Color(0xFF5A8A20), fontSize: 12)),
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

  Widget _buildVersusBlock(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VersusScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D2008), Color(0xFF5C3317)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF3D2008).withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.people_outline_rounded, color: Color(0xFFFAC775), size: 28),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mode Versus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  Text('Défie un ami et gagne des XP !', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Color(0xFFFAC775), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded, color: Color(0xFFBA7517), size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class MarqueeTicker extends StatefulWidget {
  final String text;
  const MarqueeTicker({super.key, required this.text});

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() {
    if (!_scrollController.hasClients) return;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final duration = Duration(milliseconds: (maxScrollExtent * 30).toInt());

    _scrollController.animateTo(
      maxScrollExtent,
      duration: duration,
      curve: Curves.linear,
    ).then((_) {
      if (mounted) {
        _scrollController.jumpTo(0);
        _startScrolling();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF2D5C14),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: const Color(0xFF2D5C14).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(width: 375), // Initial delay space
          Center(
            child: Text(
              widget.text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(width: 375), // End delay space
        ],
      ),
    );
  }
}
