import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../blocs/deck/deck_bloc.dart';
import '../blocs/deck/deck_event.dart';
import '../blocs/deck/deck_state.dart';
import '../../domain/entities/deck.dart';
import '../../data/local/database_helper.dart';
import 'deck_list_screen.dart';
import 'flashcard_study_screen.dart';

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
  String _sortOption = 'Date de création';

  void _confirmDelete(BuildContext context, Deck deck) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: Text('Es-tu sûr de vouloir supprimer "${deck.title}" ? Cette action libérera de l\'espace sur ton appareil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<DeckBloc>().add(DeleteDeck(deck.uuid));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fiche supprimée ✓'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    context.read<DeckBloc>().add(const LoadDecks());
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.fredokaTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
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
                icon: const Icon(Icons.tune, size: 24, color: Color(0xFF1A1A1A)),
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

          if (_sortOption == 'Nom (A-Z)') {
            filteredDecks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
          } else if (_sortOption == 'Progression') {
            filteredDecks.sort((a, b) {
              final progA = a.cardCount > 0 ? (a.masteredCount / a.cardCount) : 0.0;
              final progB = b.cardCount > 0 ? (b.masteredCount / b.cardCount) : 0.0;
              return progB.compareTo(progA);
            });
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
                  final subjectDecks = filteredDecks.where((d) => d.subject == subject['label']).toList();
                  
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
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('${decks.length} fiches', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeckListScreen(filterSubject: subject['label']))),
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

  Widget _buildDeckCard(Deck deck, Color color) {
    final totalCards = deck.cardCount;
    final displayPercentage = deck.lastQuizScore ?? 
        (totalCards > 0 ? (deck.masteredCount / totalCards * 100).round() : 0);
    
    // Change color for 'Autre' or default grey to Blue
    final isDefaultGrey = color.toARGB32() == 0xFF9E9E9E;
    final categoryColor = isDefaultGrey ? const Color(0xFF2196F3) : color;
    final masteryColor = displayPercentage < 50 ? const Color(0xFFE07B39) : categoryColor;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardStudyScreen(deckTitle: deck.title, deckUuid: deck.uuid))),
      onLongPress: () => _confirmDelete(context, deck),
      child: Container(
        width: 155,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D8CC), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: categoryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.book, color: categoryColor, size: 18),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF888888)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Share.share('Révise avec moi la fiche "${deck.title}" sur KALAN ! 📚\n\nApprends plus vite avec KALAN.');
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(context, deck),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              deck.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 2),
            Text(
              '$totalCards cartes',
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(height: 4, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFE8E4DA), borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: (displayPercentage / 100).clamp(0.0, 1.0),
                  child: Container(height: 4, decoration: BoxDecoration(color: masteryColor, borderRadius: BorderRadius.circular(4))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$displayPercentage% maîtrisé',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: masteryColor),
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
            _filterOption('Date de création', _sortOption == 'Date de création'),
            _filterOption('Nom (A-Z)', _sortOption == 'Nom (A-Z)'),
            _filterOption('Progression', _sortOption == 'Progression'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String label, bool isSelected) {
    return ListTile(
      onTap: () {
        setState(() => _sortOption = label);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2D6A2D) : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF2D6A2D)) : null,
    );
  }
}
