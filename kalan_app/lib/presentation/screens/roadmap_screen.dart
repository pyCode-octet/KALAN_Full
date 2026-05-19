import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/level_utils.dart';
import '../../data/local/database_helper.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_state.dart';
import '../widgets/tree_evolution.dart';
import 'quiz_screen.dart';
import 'create_deck_screen.dart';

class RoadmapStep {
  final int index;
  final String title;
  final String description;
  final IconData icon;
  final int level;
  final String levelTitle;
  final int xpRequired;

  const RoadmapStep({
    required this.index,
    required this.title,
    required this.description,
    required this.icon,
    required this.level,
    required this.levelTitle,
    required this.xpRequired,
  });
}

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final List<RoadmapStep> roadmapSteps = [
    const RoadmapStep(
      index: 0,
      title: 'Semailles',
      description: 'Sème tes premières graines de connaissances en créant tes premières fiches de révision.',
      icon: Icons.eco_rounded,
      level: 1,
      levelTitle: 'Graine',
      xpRequired: 0,
    ),
    const RoadmapStep(
      index: 1,
      title: 'Première Pousse',
      description: 'Les premières feuilles de ton apprentissage apparaissent. Continue sur ta lancée !',
      icon: Icons.grass_rounded,
      level: 1,
      levelTitle: 'Graine',
      xpRequired: 50,
    ),
    const RoadmapStep(
      index: 2,
      title: 'Racines Fortes',
      description: 'Ancre tes connaissances profondément dans ton esprit en révisant régulièrement.',
      icon: Icons.yard_rounded,
      level: 2,
      levelTitle: 'Baobab',
      xpRequired: 100,
    ),
    const RoadmapStep(
      index: 3,
      title: 'Tronc Solide',
      description: 'Ton savoir devient robuste et inébranlable comme le tronc du baobab centenaire.',
      icon: Icons.forest_rounded,
      level: 2,
      levelTitle: 'Baobab',
      xpRequired: 170,
    ),
    const RoadmapStep(
      index: 4,
      title: 'Ombrage Bienveillant',
      description: 'Ton savoir grandit assez pour abriter les autres et offrir sa sagesse protectrice.',
      icon: Icons.park_rounded,
      level: 2,
      levelTitle: 'Baobab',
      xpRequired: 240,
    ),
    const RoadmapStep(
      index: 5,
      title: 'L\'Étincelle',
      description: 'Une idée lumineuse jaillit dans ton esprit. Le grand feu de l\'apprentissage commence.',
      icon: Icons.lightbulb_rounded,
      level: 3,
      levelTitle: 'Feu de Brousse',
      xpRequired: 300,
    ),
    const RoadmapStep(
      index: 6,
      title: 'Propagation',
      description: 'Ton savoir se propage rapidement d\'un sujet à l\'autre. Rien ne peut t\'arrêter.',
      icon: Icons.whatshot_rounded,
      level: 3,
      levelTitle: 'Feu de Brousse',
      xpRequired: 400,
    ),
    const RoadmapStep(
      index: 7,
      title: 'Grand Brasier',
      description: 'Ta soif d\'apprendre brille si fort qu\'elle éclaire tout ton parcours.',
      icon: Icons.local_fire_department_rounded,
      level: 3,
      levelTitle: 'Feu de Brousse',
      xpRequired: 500,
    ),
    const RoadmapStep(
      index: 8,
      title: 'Paroles d\'Or',
      description: 'Apprends à raconter, structurer et conter tes leçons tel un véritable Griot.',
      icon: Icons.auto_stories_rounded,
      level: 4,
      levelTitle: 'Griot',
      xpRequired: 600,
    ),
    const RoadmapStep(
      index: 9,
      title: 'Kora Sacrée',
      description: 'Harmonise tes connaissances pour trouver le rythme parfait de tes révisions journalières.',
      icon: Icons.music_note_rounded,
      level: 4,
      levelTitle: 'Griot',
      xpRequired: 700,
    ),
    const RoadmapStep(
      index: 10,
      title: 'Légendes et Récits',
      description: 'Plonge dans les grands récits et assimile les concepts complexes avec aisance.',
      icon: Icons.history_edu_rounded,
      level: 4,
      levelTitle: 'Griot',
      xpRequired: 800,
    ),
    const RoadmapStep(
      index: 11,
      title: 'Transmission',
      description: 'Tu es prêt à transmettre ton savoir. La plus belle part de la connaissance est le partage.',
      icon: Icons.record_voice_over_rounded,
      level: 4,
      levelTitle: 'Griot',
      xpRequired: 900,
    ),
    const RoadmapStep(
      index: 12,
      title: 'Esprit d\'Initiation',
      description: 'Découvre les secrets cachés des matières sous le masque mystique du savoir.',
      icon: Icons.visibility_rounded,
      level: 5,
      levelTitle: 'Masque',
      xpRequired: 1000,
    ),
    const RoadmapStep(
      index: 13,
      title: 'Danse Sacrée',
      description: 'Jongle avec agilité entre les matières scientifiques et littéraires.',
      icon: Icons.theater_comedy_rounded,
      level: 5,
      levelTitle: 'Masque',
      xpRequired: 1120,
    ),
    const RoadmapStep(
      index: 14,
      title: 'Mystères Révélés',
      description: 'Le masque s\'ouvre et révèle ses secrets. Tu comprends la profondeur des choses.',
      icon: Icons.psychology_rounded,
      level: 5,
      levelTitle: 'Masque',
      xpRequired: 1250,
    ),
    const RoadmapStep(
      index: 15,
      title: 'Gardien des Rites',
      description: 'Tu es le gardien de ton propre parcours scolaire. Ton assiduité est ton pouvoir.',
      icon: Icons.security_rounded,
      level: 5,
      levelTitle: 'Masque',
      xpRequired: 1380,
    ),
    const RoadmapStep(
      index: 16,
      title: 'Conseil des Sages',
      description: 'Tu as atteint le sommet de Kalan. Tu es désormais un Ancêtre vénéré.',
      icon: Icons.auto_awesome_rounded,
      level: 6,
      levelTitle: 'Ancêtre',
      xpRequired: 1500,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.fredokaTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F2EA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D6A2D)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Parcours d\'Apprentissage',
            style: GoogleFonts.fredoka(
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is UserError) {
              return Center(child: Text(state.message));
            }
            if (state is UserLoaded) {
              final points = state.profile['points'] as int? ?? 0;
              final userId = state.profile['uuid'] as String? ?? '';
              final levelInfo = LevelUtils.getLevelInfo(points);

              // Trouvons l'étape en cours
              int activeIndex = 0;
              for (int i = 0; i < roadmapSteps.length; i++) {
                if (points >= roadmapSteps[i].xpRequired) {
                  activeIndex = i;
                } else {
                  break;
                }
              }

              return Column(
                children: [
                  _buildHeaderProgress(points, levelInfo),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;
                        final mapHeight = 120.0 + (roadmapSteps.length * 140.0);

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Stack(
                            children: [
                              // 1. Fond et chemin d'apprentissage
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: RoadmapPathPainter(
                                    steps: roadmapSteps,
                                    userPoints: points,
                                    screenWidth: screenWidth,
                                  ),
                                ),
                              ),

                              // 2. Bannières des Zones de Niveaux
                              _buildZoneBannerWidget('GRAINE', 'Niveau 1', const Color(0xFF2D6A2D), const Color(0xFFEAF3DE), 20),
                              _buildZoneBannerWidget('BAOBAB', 'Niveau 2', const Color(0xFF854F0B), const Color(0xFFFFF3E0), 310),
                              _buildZoneBannerWidget('FEU DE BROUSSE', 'Niveau 3', const Color(0xFFC92A2A), const Color(0xFFFFEBEE), 730),
                              _buildZoneBannerWidget('GRIOT', 'Niveau 4', const Color(0xFFE07B39), const Color(0xFFFFFDE7), 1150),
                              _buildZoneBannerWidget('MASQUE', 'Niveau 5', const Color(0xFF673AB7), const Color(0xFFF3E5F5), 1710),
                              _buildZoneBannerWidget('ANCÊTRE', 'Niveau 6', const Color(0xFF009688), const Color(0xFFE0F2F1), 2270),

                              // 3. Boutons d'étapes (Nodes)
                              SizedBox(
                                height: mapHeight,
                                width: screenWidth,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: List.generate(roadmapSteps.length, (index) {
                                    final step = roadmapSteps[index];
                                    
                                    // Déterminer le statut de l'étape
                                    bool isCompleted = points >= step.xpRequired && index < activeIndex;
                                    // L'étape active est celle que l'utilisateur est en train de tenter
                                    bool isActive = index == activeIndex;
                                    bool isLocked = points < step.xpRequired;

                                    // Si l'utilisateur est à l'XP max, la dernière étape est marquée active/complétée
                                    if (points >= roadmapSteps.last.xpRequired && index == roadmapSteps.length - 1) {
                                      isCompleted = false;
                                      isActive = true;
                                      isLocked = false;
                                    }

                                    // Position X avec oscillation sinusoïdale
                                    double x = screenWidth / 2 + 70 * sin(index * 0.8);
                                    double y = 100 + index * 140.0;

                                    return Positioned(
                                      left: x - 35, // 35 est la moitié de la taille du bouton (70)
                                      top: y - 35,
                                      child: RoadmapNodeButton(
                                        step: step,
                                        isCompleted: isCompleted,
                                        isActive: isActive,
                                        isLocked: isLocked,
                                        onTap: () => _showStepDetails(context, step, points, isCompleted, isActive, isLocked, userId),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeaderProgress(int points, LevelInfo levelInfo) {
    final double progress = (points / levelInfo.nextLevelPoints).clamp(0.0, 1.0);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF3DE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: TreeEvolution(stage: levelInfo.level, size: 36),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression Actuelle',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text(
                          levelInfo.title.toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D6A2D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Niveau ${levelInfo.level}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$points XP',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D6A2D)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E4DA),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A2D),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneBannerWidget(String title, String levelSubtitle, Color color, Color bgColor, double top) {
    return Positioned(
      top: top - 18,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: color, size: 14),
              const SizedBox(width: 8),
              Text(
                '$levelSubtitle : $title',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStepDetails(
    BuildContext context,
    RoadmapStep step,
    int userPoints,
    bool isCompleted,
    bool isActive,
    bool isLocked,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Petite barre grise du haut
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Badge / Icône de l'étape
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: isLocked 
                      ? Colors.grey.shade200 
                      : (isCompleted ? const Color(0xFFEAF3DE) : const Color(0xFFFFF3E0)),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLocked 
                        ? Colors.grey.shade300 
                        : (isCompleted ? const Color(0xFF2D6A2D) : const Color(0xFFE8C87A)),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isLocked ? Icons.lock_rounded : step.icon,
                  color: isLocked 
                      ? Colors.grey.shade500 
                      : (isCompleted ? const Color(0xFF2D6A2D) : const Color(0xFF854F0B)),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre de l'étape
            Center(
              child: Text(
                step.title,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),

            // Sous-titre de niveau
            Center(
              child: Text(
                'Thème : ${step.levelTitle} (Requis: ${step.xpRequired} XP)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isLocked ? Colors.red.shade700 : const Color(0xFF2D6A2D),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(
                step.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Statut & Action
            if (isLocked) ...[
              // Barre de progression vers cette étape
              Text(
                'Progression requise',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (userPoints / step.xpRequired).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$userPoints / ${step.xpRequired} XP',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Étape Verrouillée', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ] else ...[
              // Bouton Lancer un Quiz ou Réviser
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D6A2D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: () async {
                  Navigator.pop(sheetContext); // Fermer le bottom sheet

                  // Essayer de charger les decks locaux pour lancer un quiz
                  final decks = await DatabaseHelper.instance.getDecks(userId);
                  if (!context.mounted) return;

                  if (decks.isEmpty) {
                    // Pas de fiches créées ! Proposer de créer une fiche
                    _showNoDecksWarning(context);
                  } else {
                    // Sélectionner un deck aléatoire ou le dernier créé
                    final randomDeck = decks[Random().nextInt(decks.length)];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          deckUuid: randomDeck['uuid'],
                          deckTitle: randomDeck['title'] ?? 'Quiz Rapide',
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  isCompleted ? 'Réviser avec un Quiz' : 'Relever le Défi ! (+10 XP)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text(
                  'Plus tard',
                  style: TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNoDecksWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Aucune fiche disponible', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Tu n\'as pas encore créé de fiches de révision ! Crée ta première fiche pour pouvoir lancer des quiz et progresser dans le parcours.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6A2D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Fermer la boîte de dialogue
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateDeckScreen()),
              );
            },
            child: const Text('Créer une Fiche', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class RoadmapNodeButton extends StatefulWidget {
  final RoadmapStep step;
  final bool isCompleted;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;

  const RoadmapNodeButton({
    super.key,
    required this.step,
    required this.isCompleted,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<RoadmapNodeButton> createState() => _RoadmapNodeButtonState();
}

class _RoadmapNodeButtonState extends State<RoadmapNodeButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RoadmapNodeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isActive && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double size = 70.0;
    
    // Choisir les couleurs du bouton
    Color baseColor;
    Color shadowColor;
    Color iconColor;

    if (widget.isCompleted) {
      baseColor = const Color(0xFF58CC02); // Vert vif
      shadowColor = const Color(0xFF46A302); // Vert ombre
      iconColor = Colors.white;
    } else if (widget.isActive) {
      baseColor = const Color(0xFFE8C87A); // Or
      shadowColor = const Color(0xFFCBB06B); // Or ombre
      iconColor = const Color(0xFF2D6A2D);
    } else {
      baseColor = const Color(0xFFE5E5E5); // Gris
      shadowColor = const Color(0xFFAFAFAF); // Gris ombre
      iconColor = const Color(0xFF8F8F8F);
    }

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Halo de pulsation pour le nœud actif
          if (widget.isActive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double scale = 1.0 + (_pulseController.value * 0.35);
                final double opacity = 1.0 - _pulseController.value;
                return Container(
                  width: size * scale,
                  height: size * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8C87A).withOpacity(opacity * 0.6),
                      width: 5,
                    ),
                  ),
                );
              },
            ),

          // Ombre 3D du bouton (placée légèrement en dessous)
          Positioned(
            top: 6,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: shadowColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Face supérieure du bouton
          AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            margin: EdgeInsets.only(top: _isPressed ? 6.0 : 0.0),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                widget.isLocked ? Icons.lock_rounded : widget.step.icon,
                color: iconColor,
                size: widget.isLocked ? 24 : 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoadmapPathPainter extends CustomPainter {
  final List<RoadmapStep> steps;
  final int userPoints;
  final double screenWidth;

  RoadmapPathPainter({
    required this.steps,
    required this.userPoints,
    required this.screenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (steps.isEmpty) return;

    // Peindre les zones d'arrière-plan de manière esthétique
    _paintBackgroundZones(canvas, size);

    final paintCompleted = Paint()
      ..color = const Color(0xFF58CC02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final paintLocked = Paint()
      ..color = const Color(0xFFE5E5E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Dessiner le chemin reliant les points
    for (int i = 0; i < steps.length - 1; i++) {
      final stepCurr = steps[i + 1];

      // Coordonnées de départ et d'arrivée
      double xPrev = screenWidth / 2 + 70 * sin(i * 0.8);
      double yPrev = 100 + i * 140.0;

      double xCurr = screenWidth / 2 + 70 * sin((i + 1) * 0.8);
      double yCurr = 100 + (i + 1) * 140.0;

      // Segment considéré comme complété si l'utilisateur a atteint l'étape d'arrivée
      bool isCompletedSegment = userPoints >= stepCurr.xpRequired;

      final path = Path();
      path.moveTo(xPrev, yPrev);
      path.cubicTo(
        xPrev, yPrev + 70, // point de contrôle 1
        xCurr, yCurr - 70, // point de contrôle 2
        xCurr, yCurr,
      );

      if (isCompletedSegment) {
        canvas.drawPath(path, paintCompleted);
      } else {
        _drawDashedPath(canvas, path, paintLocked);
      }
    }
  }

  void _paintBackgroundZones(Canvas canvas, Size size) {
    // Zones de couleur de fond douces
    final List<Map<String, dynamic>> zones = [
      {'top': 0.0, 'bottom': 310.0, 'color': const Color(0xFFF1F8E9)}, // Graine (vert)
      {'top': 310.0, 'bottom': 730.0, 'color': const Color(0xFFFFF3E0)}, // Baobab (orange)
      {'top': 730.0, 'bottom': 1150.0, 'color': const Color(0xFFFFEBEE)}, // Feu de brousse (rouge)
      {'top': 1150.0, 'bottom': 1710.0, 'color': const Color(0xFFFFFDE7)}, // Griot (jaune)
      {'top': 1710.0, 'bottom': 2270.0, 'color': const Color(0xFFF3E5F5)}, // Masque (violet)
      {'top': 2270.0, 'bottom': size.height, 'color': const Color(0xFFE0F2F1)}, // Ancêtre (cyan/turquoise)
    ];

    for (var z in zones) {
      final rect = Rect.fromLTRB(0, z['top'], screenWidth, z['bottom']);
      final paint = Paint()..color = z['color'];
      canvas.drawRect(rect, paint);
      
      // Ajouter une fine ligne séparatrice
      final separatorPaint = Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..strokeWidth = 2;
      canvas.drawLine(Offset(0, z['bottom']), Offset(screenWidth, z['bottom']), separatorPaint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = (distance + dashWidth < metric.length) 
            ? dashWidth 
            : metric.length - distance;
        final Path extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoadmapPathPainter oldDelegate) {
    return oldDelegate.userPoints != userPoints || oldDelegate.screenWidth != screenWidth;
  }
}
