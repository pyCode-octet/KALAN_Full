import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/badge/badge_bloc.dart';
import '../blocs/badge/badge_event.dart';
import '../blocs/badge/badge_state.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Tous';
  final List<String> _categories = ['Tous', 'Apprentissage', 'Quiz', 'Social'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); 
    });
    context.read<BadgeBloc>().add(LoadBadges());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredBadges(List<Map<String, dynamic>> allBadges, Set<String> unlockedKeys) {
    List<Map<String, dynamic>> filtered = allBadges;

    // 1. Filtrer par onglet (Tous / Obtenus / A debloquer)
    if (_tabController.index == 1) {
      filtered = filtered.where((b) => unlockedKeys.contains(b['id'])).toList();
    } else if (_tabController.index == 2) {
      filtered = filtered.where((b) => !unlockedKeys.contains(b['id'])).toList();
    }

    // 2. Filtrer par categorie
    if (_selectedCategory != 'Tous') {
      filtered = filtered.where((b) => b['category']?.toString().toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes badges',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<BadgeBloc, BadgeState>(
        builder: (context, state) {
          if (state is BadgeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BadgeLoaded) {
            final unlockedKeys = state.unlockedBadges.map((b) => b.badgeKey).toSet();
            final filteredBadges = _getFilteredBadges(state.allBadges, unlockedKeys);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsHeader(unlockedKeys.length, state.allBadges.length),
                _buildTabs(),
                _buildCategoryFilters(),
                Expanded(
                  child: filteredBadges.isEmpty
                      ? _buildEmptyState()
                      : _buildBadgesGrid(filteredBadges, unlockedKeys),
                ),
              ],
            );
          }
          
          if (state is BadgeError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatsHeader(int obtained, int total) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A2D),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$obtained / $total', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Badges débloqués', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: const Color(0xFF2D6A2D),
        labelColor: const Color(0xFF2D6A2D),
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: 'Tous'),
          Tab(text: 'Obtenus'),
          Tab(text: 'À débloquer'),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: FilterChip(
              label: Text(cat),
              selected: isActive,
              onSelected: (val) => setState(() => _selectedCategory = cat),
              selectedColor: const Color(0xFF2D6A2D).withOpacity(0.2),
              checkmarkColor: const Color(0xFF2D6A2D),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesGrid(List<Map<String, dynamic>> badges, Set<String> unlockedKeys) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isUnlocked = unlockedKeys.contains(badge['id']);
        return Opacity(
          opacity: isUnlocked ? 1.0 : 0.5,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: isUnlocked ? Border.all(color: const Color(0xFF2D6A2D), width: 2) : null,
                ),
                child: Text(badge['emoji'] ?? '🏅', style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 8),
              Text(
                badge['label'],
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Aucun badge dans cette catégorie'));
  }
}
