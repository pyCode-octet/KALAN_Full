import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/deck/deck_bloc.dart';
import '../blocs/deck/deck_event.dart';
import '../blocs/deck/deck_state.dart';
import '../../domain/entities/deck.dart';
import '../../data/local/database_helper.dart';
import 'deck_list_screen.dart';
import 'create_deck_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _activeTab = 'Toutes';
  final List<String> _tabs = ['Toutes', 'Récentes', 'Favoris'];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DeckBloc>().add(const LoadDecks());
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F2EA),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabs(),
              Expanded(child: _buildCategoryList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_isSearching)
            const Text(
              'Librairie',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            )
          else
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une fiche...',
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _isSearching = !_isSearching),
                icon: Icon(_isSearching ? Icons.close : Icons.search, size: 24, color: const Color(0xFF1A1A1A)),
              ),
              IconButton(
                onPressed: () => _showFilterBottomSheet(),
                icon: const Icon(Icons.tune, size: 24, color: const Color(0xFF1A1A1A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isActive = _activeTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2D6A2D) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isActive ? null : Border.all(color: const Color(0xFFD0CCC0)),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF7A6652),
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryList() {
    return BlocBuilder<DeckBloc, DeckState>(
      builder: (context, state) {
        if (state is DeckLoading) return const Center(child: CircularProgressIndicator());
        if (state is DeckLoaded) {
          final allDecks = state.decks;
          final query = _searchController.text.toLowerCase();
          final filteredDecks = allDecks.where((d) => d.title.toLowerCase().contains(query)).toList();

          if (filteredDecks.isEmpty) {
            return const Center(child: Text('Aucune fiche. Crée ta première fiche !'));
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseHelper.instance.getAllSubjects(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final subjects = snapshot.data!;
              
              final subjectsWithDecks = subjects.where((s) {
                return filteredDecks.any((d) => d.subject == s['label']);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                itemCount: subjectsWithDecks.length,
                itemBuilder: (context, index) {
                  final subject = subjectsWithDecks[index];
                  final subjectDecks = filteredDecks.where((d) => d.subject == subject['label']).cast<Deck>().toList();
                  
                  return _buildCategorySection(subject, subjectDecks);
                },
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> subject, List<Deck> decks) {
    final color = Color(subject['color'] as int);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.school, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(subject['label'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('${decks.length} fiches', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeckListScreen())),
                child: const Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF2D6A2D), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: decks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final deck = decks[index];
              return _buildDeckCard(deck, color);
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDeckCard(Map<String, dynamic> deck, Color color) {
    final totalCards = deck['cardCount'] ?? 0;
    final masteredCards = deck['masteredCount'] ?? 0;
    final masteryPercentage = totalCards > 0 ? (masteredCards / totalCards * 100).round() : 0;
    final masteryColor = masteryPercentage < 50 ? const Color(0xFFE07B39) : color;

    return GestureDetector(
      onTap: () {
        // Navigation vers le détail du deck
      },
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D8CC), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.book, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              deck['title'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 4),
            Text(
              '${deck['level'] ?? 'Niveau'} · $totalCards cartes',
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFE8E4DA), borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: (masteryPercentage / 100).clamp(0.0, 1.0),
                  child: Container(height: 4, decoration: BoxDecoration(color: masteryColor, borderRadius: BorderRadius.circular(4))),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$masteryPercentage% maîtrisé',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: masteryColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trier par', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _filterOption('Date de création', true),
            _filterOption('Nom (A-Z)', false),
            _filterOption('Progression', false),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String label, bool isSelected) {
    return ListTile(
      onTap: () => Navigator.pop(context),
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2D6A2D) : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF2D6A2D)) : null,
    );
  }
}
