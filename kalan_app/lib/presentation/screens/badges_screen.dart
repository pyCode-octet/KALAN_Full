import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/badge/badge_bloc.dart';
import '../blocs/badge/badge_event.dart';
import '../blocs/badge/badge_state.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';

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
      backgroundColor: const Color(0xFFF5F2EA), // Fond beige crème conforme au HTML
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F2EA),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 24),
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
                _buildStatsHeader(context, unlockedKeys.length, state.allBadges.length),
                _buildTabs(),
                const SizedBox(height: 12),
                _buildCategoryFilters(),
                const SizedBox(height: 12),
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

  Widget _buildStatsHeader(BuildContext context, int obtained, int total) {
    int xpPoints = 1250;
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoaded) {
      xpPoints = userState.profile['points'] as int? ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Badges obtenus
            Expanded(
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    '$obtained',
                    style: const TextStyle(
                      color: Color(0xFF2D6A2D),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Badges obtenus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // À débloquer
            Expanded(
              child: Column(
                children: [
                  const Text('🔒', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    '${total - obtained}',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'À débloquer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Points XP
            Expanded(
              child: Column(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    '$xpPoints',
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Points XP',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFECE7DB),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: List.generate(3, (index) {
            final labels = ['Tous', 'Obtenus', 'À débloquer'];
            final isActive = _tabController.index == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _tabController.index = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2D6A2D) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF666666),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2D6A2D) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? const Color(0xFF2D6A2D) : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF666666),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesGrid(List<Map<String, dynamic>> badges, Set<String> unlockedKeys) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isUnlocked = unlockedKeys.contains(badge['id']);
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isUnlocked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/badges/${badge['image_path']}',
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                      child: Center(
                        child: Text(badge['emoji'] ?? '🏅', style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔒', style: TextStyle(fontSize: 22)),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                isUnlocked ? (badge['label'] ?? '') : '???',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isUnlocked ? (badge['description'] ?? '') : 'Badge secret',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Aucun badge dans cette catégorie',
        style: TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

