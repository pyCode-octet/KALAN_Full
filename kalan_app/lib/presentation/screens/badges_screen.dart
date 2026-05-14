import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/badge/badge_bloc.dart';
import '../blocs/badge/badge_event.dart';
import '../blocs/badge/badge_state.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import '../../data/local/database_helper.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allBadges = [];
  bool _isLoadingBadges = true;
  late TabController _tabController;
  String _selectedCategory = 'Tous';
  final List<String> _categories = ['Tous', 'Apprentissage', 'Quiz', 'Social'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Pour rafraichir les filtres quand on change d'onglet
    });
    context.read<BadgeBloc>().add(LoadBadges());
    _loadBadgesFromDb();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBadgesFromDb() async {
    final dbBadges = await DatabaseHelper.instance.getAllBadges();
    if (mounted) {
      setState(() {
        _allBadges = dbBadges;
        _isLoadingBadges = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredBadges(Set<String> unlockedKeys) {
    List<Map<String, dynamic>> filtered = _allBadges;

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
      backgroundColor: const Color(0xFFF5F2EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F2EA),
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
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: const Color(0xFF2D6A2D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<BadgeBloc, BadgeState>(
        builder: (context, state) {
          if (state is BadgeLoading || _isLoadingBadges) {
            return const Center(child: CircularProgressIndicator());
          }

          final unlockedKeys = (state is BadgeLoaded)
              ? state.unlockedBadges.map((b) => b.badgeKey).toSet()
              : <String>{};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  height: 40,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicator: const BoxDecoration(), // On gere l'UI manuellement
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.only(right: 8),
                    tabs: [
                      _buildTab('Tous', _tabController.index == 0),
                      _buildTab('Obtenus', _tabController.index == 1),
                      _buildTab('À débloquer', _tabController.index == 2),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Section
                      _buildStatsSection(unlockedKeys),

                      const SizedBox(height: 24),

                      // Category Filter
                      const Text(
                        'Badges débloqués',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryFilters(),

                      const SizedBox(height: 16),

                      // Badges Grids
                      _buildBadgesGrid(unlockedKeys),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2D6A2D) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : const Color(0xFF666666),
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatsSection(Set<String> unlockedKeys) {
    final obtainedCount = unlockedKeys.length;
    final toUnlockCount = _allBadges.length - obtainedCount;

    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        final points = (userState is UserLoaded) ? userState.profile['points'] as int? ?? 0 : 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('🏆', obtainedCount.toString(), 'Badges obtenus', const Color(0xFF2D6A2D)),
              _buildStatItem('🔒', toUnlockCount.toString(), 'À débloquer', const Color(0xFF666666)),
              _buildStatItem('⭐', points.toString(), 'Points XP', const Color(0xFFFF9800)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String icon, String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isActive = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2D6A2D) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isActive ? null : Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF666666),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBadgesGrid(Set<String> unlockedKeys) {
    final filteredBadges = _getFilteredBadges(unlockedKeys);

    if (filteredBadges.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: const Text('Aucun badge ne correspond à ces critères', style: TextStyle(color: Color(0xFF666666))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: filteredBadges.length,
      itemBuilder: (context, index) {
        final badge = filteredBadges[index];
        final isUnlocked = unlockedKeys.contains(badge['id']);

        if (isUnlocked) {
          return _buildUnlockedBadgeItem(badge);
        } else {
          return _buildLockedBadgeItem();
        }
      },
    );
  }

  Widget _buildUnlockedBadgeItem(Map<String, dynamic> badge) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildBadgeImage(badge['image_path'], badge['emoji']),
          const SizedBox(height: 8),
          Text(
            badge['label'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 2),
          Text(
            badge['description'] ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBadgeItem() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0).withOpacity(0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, color: Color(0xFF999999), size: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            '???',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 2),
          const Text(
            'Badge secret',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeImage(String? imagePath, String emoji) {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF5F2EA),
      ),
      child: ClipOval(
        child: imagePath != null
            ? Image.asset(
                'assets/badges/$imagePath',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              )
            : Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
      ),
    );
  }
}
