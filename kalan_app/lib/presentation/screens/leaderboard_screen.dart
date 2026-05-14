import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/leaderboard/leaderboard_bloc.dart';
import '../blocs/leaderboard/leaderboard_event.dart';
import '../blocs/leaderboard/leaderboard_state.dart';
import '../../data/remote/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _currentScope = 'national';

  @override
  void initState() {
    super.initState();
    context.read<LeaderboardBloc>().add(LoadLeaderboard(scope: _currentScope));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Classement')),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
              builder: (context, state) {
                if (state is LeaderboardLoading) return const Center(child: CircularProgressIndicator());
                if (state is LeaderboardError) return Center(child: Text(state.message));
                if (state is LeaderboardLoaded) {
                  if (state.entries.isEmpty) return const Center(child: Text('Aucune donnée disponible.'));
                  
                  final topThree = state.entries.take(3).toList();
                  final remaining = state.entries.skip(3).toList();

                  return Column(
                    children: [
                      _buildTopThree(topThree),
                      Expanded(child: _buildLeaderboardList(remaining, state.entries.length)),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _tabItem('National', 'national'),
          _tabItem('École', 'school'),
          _tabItem('Classe', 'class'),
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
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }

  Widget _buildTopThree(List<dynamic> topThree) {
    if (topThree.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (topThree.length >= 2) 
            _topUser(topThree[1].pseudo, '2', topThree[1].points.toString(), topThree[1].avatar, 70),
          if (topThree.length < 2) SizedBox(width: 70), // Placeholder
          SizedBox(width: 12),
          if (topThree.isNotEmpty)
            _topUser(topThree[0].pseudo, '1', topThree[0].points.toString(), topThree[0].avatar, 90, isFirst: true),
          SizedBox(width: 12),
          if (topThree.length >= 3) 
            _topUser(topThree[2].pseudo, '3', topThree[2].points.toString(), topThree[2].avatar, 70),
          if (topThree.length < 3) SizedBox(width: 70), // Placeholder
        ],
      ),
    );
  }

  Widget _topUser(String name, String rank, String points, String? avatar, double size, {bool isFirst = false}) {
    return Column(
      children: [
        if (isFirst) Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
        CircleAvatar(
          radius: size / 2, 
          backgroundColor: AppColors.secondary,
          backgroundImage: avatar != null ? NetworkImage(avatar) as ImageProvider : const AssetImage('assets/avatars/avatar1.png'),
        ),
        SizedBox(height: 8),
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text('$points pts', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
        Container(
          margin: EdgeInsets.only(top: 4),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(color: isFirst ? Colors.amber : Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
          child: Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(List<dynamic> remaining, int totalLength) {
    final currentUserId = SupabaseService.currentUser?.id;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: remaining.length,
      itemBuilder: (context, index) {
        final entry = remaining[index];
        final rank = index + 4;
        final isMe = entry.userId == currentUserId;

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary.withValues(alpha: 0.1) : Colors.white, 
            borderRadius: BorderRadius.circular(16),
            border: isMe ? Border.all(color: AppColors.primary, width: 1) : null,
          ),
          child: Row(
            children: [
              Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16)),
              SizedBox(width: 16),
              CircleAvatar(
                radius: 20, 
                backgroundColor: AppColors.secondary,
                backgroundImage: entry.avatar != null ? NetworkImage(entry.avatar) as ImageProvider : const AssetImage('assets/avatars/avatar1.png'),
              ),
              SizedBox(width: 12),
              Text(isMe ? 'Moi (${entry.pseudo})' : entry.pseudo, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              Text('${entry.points} pts', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onBackground)),
            ],
          ),
        );
      },
    );
  }
}
