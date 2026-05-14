import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kalan_app/presentation/blocs/sync/sync_bloc.dart';
import 'package:kalan_app/presentation/blocs/sync/sync_state.dart';
import 'package:kalan_app/presentation/screens/settings_screen.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/deck/deck_bloc.dart';
import '../blocs/deck/deck_event.dart';
import '../blocs/deck/deck_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_shimmer.dart';
import 'flashcard_study_screen.dart';
import 'share_screen.dart';
import 'create_deck_screen.dart';
import '../../data/local/database_helper.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> subjectConfigs = {
      'SVT': {'color': const Color(0xFF2D6A2D), 'bg': const Color(0xFFEAF3DE), 'icon': Icons.biotech_rounded},
      'Histoire-Géo': {'color': const Color(0xFF854F0B), 'bg': const Color(0xFFFAEEDA), 'icon': Icons.public_rounded},
      'Mathématiques': {'color': const Color(0xFF185FA5), 'bg': const Color(0xFFE6F1FB), 'icon': Icons.functions_rounded},
      'Physique-Chimie': {'color': const Color(0xFF6A2D9F), 'bg': const Color(0xFFEEEDFE), 'icon': Icons.science_rounded},
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes Decks'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: BlocBuilder<DeckBloc, DeckState>(
        builder: (context, state) {
          if (state is DeckLoading) return const LoadingShimmer();
          if (state is DeckError) return Center(child: Text(state.message));
          if (state is DeckLoaded) {
            final decks = state.decks;
            if (decks.isEmpty) return const EmptyState(title: 'Aucun deck', subtitle: 'Commence par créer ton premier deck de révision !');

            // Group decks by subject
            final Map<String, List<dynamic>> decksBySubject = {};
            for (var deck in decks) {
              final subject = deck.subject ?? 'Autres';
              if (!decksBySubject.containsKey(subject)) {
                decksBySubject[subject] = [];
              }
              decksBySubject[subject]!.add(deck);
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: decksBySubject.length,
              itemBuilder: (context, index) {
                final subject = decksBySubject.keys.elementAt(index);
                final decks = decksBySubject[subject]!;
                final config = subjectConfigs[subject] ?? {
                  'color': AppColors.primary,
                  'bg': AppColors.primary.withOpacity(0.1),
                  'icon': Icons.school_rounded
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: config['color'], borderRadius: BorderRadius.circular(6)),
                            child: Icon(config['icon'], color: Colors.white, size: 14),
                          ),
                          SizedBox(width: 8),
                          Text(subject, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('${decks.length} decks', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    ...decks.map((deck) => _buildDeckItem(context, deck, config)).toList(),
                  ],
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_deck',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateDeckScreen())),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDeckItem(BuildContext context, dynamic deck, Map<String, dynamic> config) {
    return Dismissible(
      key: Key(deck.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => context.read<DeckBloc>().add(DeleteDeck(deck.uuid)),
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardStudyScreen(deckTitle: deck.title, deckUuid: deck.uuid))),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: config['bg'], borderRadius: BorderRadius.circular(12)),
                child: Icon(config['icon'], color: config['color'], size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(deck.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    FutureBuilder<int>(
                      future: DatabaseHelper.instance.getCardCount(deck.uuid),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Text('${deck.level ?? '3ème'} · $count cartes', style: TextStyle(fontSize: 12, color: Colors.grey));
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.share_rounded, color: AppColors.secondary, size: 20),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShareScreen())),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
