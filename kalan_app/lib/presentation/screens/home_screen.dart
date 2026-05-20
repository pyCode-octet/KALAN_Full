import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';
import '../blocs/notification/notification_bloc.dart';
import '../blocs/notification/notification_event.dart';
import '../blocs/badge/badge_bloc.dart';
import '../blocs/badge/badge_event.dart';
import '../blocs/badge/badge_state.dart';
import '../blocs/deck/deck_bloc.dart';
import '../blocs/deck/deck_state.dart';
import '../blocs/quiz/quiz_bloc.dart';
import '../blocs/quiz/quiz_state.dart';
import '../widgets/badge_unlock_popup.dart';
import '../widgets/level_up_popup.dart';
import '../../core/utils/level_utils.dart';
import '../widgets/tree_evolution.dart';
import 'home_dashboard.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'create_deck_screen.dart';
import 'camera_ocr_screen.dart';
import 'generating_screen.dart';
import '../../services/pdf_service.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../../ai/model_downloader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int? _lastKnownLevel;

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(LoadUserProfile());
    _startSilentModelDownload();
  }

  void _startSilentModelDownload() async {
    try {
      final hasModel = await ModelDownloader.isModelDownloaded();
      if (!hasModel) {
        debugPrint("[KALAN AI] Modèle local manquant. Démarrage du téléchargement silencieux en arrière-plan...");
        ModelDownloader.downloadModel().listen(
          (progress) {
            if (progress > 0) {
              debugPrint("[KALAN AI] Progression téléchargement silencieux: ${(progress * 100).toInt()}%");
            }
          },
          onDone: () {
            debugPrint("[KALAN AI] Téléchargement silencieux terminé avec succès ! L'IA offline est active.");
          },
          onError: (e) {
            debugPrint("[KALAN AI] Échec du téléchargement silencieux : $e. Une nouvelle tentative aura lieu au prochain démarrage.");
          },
          cancelOnError: true,
        );
      } else {
        debugPrint("[KALAN AI] Modèle local déjà présent et opérationnel !");
      }
    } catch (e) {
      debugPrint("[KALAN AI] Erreur lors de l'initialisation du téléchargement : $e");
    }
  }

  final List<Widget> _screens = [
    const HomeDashboard(),
    const LibraryScreen(),
    const CreateDeckScreen(), 
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UserBloc, UserState>(
          listener: (context, state) {
            if (state is UserLoaded) {
              final userId = state.profile['uuid'] ?? 'guest';
              context.read<NotificationBloc>().add(LoadNotifications(userId));
              // Check badges on app start/profile load
              context.read<BadgeBloc>().add(CheckNewBadges());

              // Level up detection
              final points = state.profile['points'] as int? ?? 0;
              final currentLevel = LevelUtils.getLevelInfo(points).level;

              if (_lastKnownLevel != null && currentLevel > _lastKnownLevel!) {
                final levelInfo = LevelUtils.getLevelInfo(points);
                LevelUpPopup.show(
                  context,
                  level: levelInfo.level,
                  title: levelInfo.title,
                  icon: levelInfo.icon,
                  pointsReward: 50,
                  flashcardsCount: state.stats['flashcardCount'] ?? 0,
                );
              }
              _lastKnownLevel = currentLevel;
            }
          },
        ),
        BlocListener<BadgeBloc, BadgeState>(
          listener: (context, state) {
            if (state is BadgeJustUnlocked) {
              BadgeUnlockPopup.show(
                context,
                label: state.label,
                emoji: state.emoji,
                imagePath: state.imagePath,
                color: state.color,
              );
            }
          },
        ),
        BlocListener<DeckBloc, DeckState>(
          listener: (context, state) {
            if (state is DeckLoaded) {
              context.read<BadgeBloc>().add(CheckNewBadges());
            }
          },
        ),
        BlocListener<QuizBloc, QuizState>(
          listener: (context, state) {
            if (state is QuizSubmitted) {
              context.read<BadgeBloc>().add(CheckNewBadges());
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            height: 80,
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Le fond blanc avec découpe incurvée (notch)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 65,
                  child: CustomPaint(
                    painter: NotchedCardPainter(
                      color: Colors.white,
                      shadowColor: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                // La ligne des icônes d'onglets avec les noms
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 65,
                  child: BlocBuilder<UserBloc, UserState>(
                    builder: (context, state) {
                      int currentStage = 1;
                      if (state is UserLoaded) {
                        final points = state.profile['points'] as int? ?? 0;
                        currentStage = LevelUtils.getLevelInfo(points).level;
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _navItem(0, Icons.description_outlined, Icons.description_rounded, 'Accueil'),
                          _navItem(1, Icons.auto_stories_outlined, Icons.auto_stories_rounded, 'Librairie'),
                          const SizedBox(width: 60), // Espace central réservé au bouton
                          _navItem(3, null, null, 'Niveau', customIcon: TreeEvolution(stage: currentStage, size: 22)),
                          _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
                        ],
                      );
                    },
                  ),
                ),
                // Le point indicateur vert glissant (placé sous le texte)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    alignment: Alignment(-0.8 + (_currentIndex * 0.4), 0.0),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Le grand bouton central vert encastré avec un "+"
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _showCreateOptions(context),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded, // Symbole "+" au milieu
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Créer une nouvelle fiche',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 24),
              _createOptionItem(
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF2D6A2D),
                title: 'Scanner un cours',
                subtitle: 'Prendre une photo de tes notes',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraOCRScreen()));
                },
              ),
              const SizedBox(height: 16),
              _createOptionItem(
                icon: Icons.photo_library_rounded,
                color: const Color(0xFF185FA5),
                title: 'Importer une image',
                subtitle: 'Depuis ta galerie photos',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraOCRScreen()));
                },
              ),
              const SizedBox(height: 16),
              _createOptionItem(
                icon: Icons.picture_as_pdf_rounded,
                color: const Color(0xFFE24B4A),
                title: 'Importer un PDF',
                subtitle: 'Fichier PDF (max 10 pages)',
                onTap: () async {
                  final parentNavigator = Navigator.of(this.context);
                  final parentScaffold = ScaffoldMessenger.of(this.context);
                  Navigator.pop(context);

                  try {
                    fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
                      type: fp.FileType.custom,
                      allowedExtensions: ['pdf'],
                      withData: false,
                    );

                    if (result != null) {
                      final singleFile = result.files.single;
                      
                      if (!mounted) return;
                      showDialog(
                        context: this.context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );

                      final text = await PdfService().extractText(
                        filePath: singleFile.path,
                        bytes: singleFile.bytes,
                      );

                      if (mounted) {
                        parentNavigator.pop(); // Fermer le loader
                        if (text.isEmpty) {
                          parentScaffold.showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Ce PDF ne contient pas de texte sélectionnable (PDF scanné). Utilise l'option 'Scanner un cours' !",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 6),
                            ),
                          );
                        } else {
                          parentNavigator.push(
                            MaterialPageRoute(builder: (_) => GeneratingScreen(ocrText: text)),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      parentScaffold.showSnackBar(
                        SnackBar(content: Text('Erreur lors de l\'import : $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createOptionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData? iconOutlined, IconData? iconFilled, String label, {Widget? customIcon}) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 60,
        height: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (customIcon != null)
              SizedBox(
                width: 22,
                height: 22,
                child: Opacity(
                  opacity: isSelected ? 1.0 : 0.6,
                  child: customIcon,
                ),
              )
            else
              Icon(
                isSelected ? iconFilled : iconOutlined,
                color: isSelected ? AppColors.primary : const Color(0xFFB0A89A),
                size: 22,
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : const Color(0xFFB0A89A),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotchedCardPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  NotchedCardPainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    
    // Coins supérieurs de la barre (effet arrondi moderne)
    const double topRadius = 24;
    
    path.moveTo(0, topRadius);
    path.quadraticBezierTo(0, 0, topRadius, 0);
    
    double centerX = size.width / 2;
    double notchHeight = 28;
    
    double startX = centerX - 45;
    double endX = centerX + 45;
    
    path.lineTo(startX, 0);
    
    // Courbe de Bézier cubique pour une encoche centrale ultra-fluide (effet notch)
    path.cubicTo(
      centerX - 25, 0,
      centerX - 22, notchHeight,
      centerX, notchHeight,
    );
    path.cubicTo(
      centerX + 22, notchHeight,
      centerX + 25, 0,
      endX, 0,
    );
    
    path.lineTo(size.width - topRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, topRadius);
    
    // Lignes du bas
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Peindre l'ombre au-dessus
    canvas.drawPath(path.shift(const Offset(0, -3)), shadowPaint);
    
    // Peindre la forme de la barre
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
