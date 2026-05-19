import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kalan_app/presentation/blocs/deck/deck_bloc.dart';
import 'package:kalan_app/presentation/blocs/deck/deck_event.dart';
import 'package:kalan_app/presentation/screens/flashcard_study_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../data/local/database_helper.dart';
import '../../services/local_ai_service.dart';
import '../../data/repositories/deck_repository_impl.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';

class GeneratingScreen extends StatefulWidget {
  final String ocrText;
  const GeneratingScreen({super.key, required this.ocrText});

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> with TickerProviderStateMixin {
  final LocalAIService _aiService = LocalAIService();
  List<Map<String, String>> _flashcards = [];
  String _selectedSubject = 'Littérature';
  String _selectedLevel = '3ème';
  List<Map<String, dynamic>> _subjects = [];
  final List<String> _levels = ['6ème', '5ème', '4ème', '3ème', '2nde', '1ère', 'Terminale'];
  bool _isConfiguring = true;

  late AnimationController _rotationController;
  late AnimationController _pulseController;
  int _currentStep = 0;
  Timer? _stepTimer;
  bool _aiFinished = false;
  final Uuid _uuid = const Uuid();
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadSubjects();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _stepTimer?.cancel();
    super.dispose();
  }

  String _detectSubject(String text) {
    final lowerText = text.toLowerCase();
    
    // 1. Détection Sciences (Maths, SVT, Physique, Informatique)
    if (lowerText.contains('fraction') ||
        lowerText.contains('équation') ||
        lowerText.contains('calculer') ||
        lowerText.contains('géométrie') ||
        lowerText.contains('triangle') ||
        lowerText.contains('théorème') ||
        lowerText.contains('nombre') ||
        lowerText.contains('fonction') ||
        lowerText.contains('cellule') ||
        lowerText.contains('plante') ||
        lowerText.contains('corps humain') ||
        lowerText.contains('organe') ||
        lowerText.contains('adn') ||
        lowerText.contains('génétique') ||
        lowerText.contains('reproduction') ||
        lowerText.contains('chimie') ||
        lowerText.contains('physique') ||
        lowerText.contains('atome') ||
        lowerText.contains('molécule') ||
        lowerText.contains('force') ||
        lowerText.contains('vitesse') ||
        lowerText.contains('pesanteur') ||
        lowerText.contains('informatique') ||
        lowerText.contains('ordinateur') ||
        lowerText.contains('code') ||
        lowerText.contains('programmation') ||
        lowerText.contains('algorithme')) {
      return 'Sciences';
    }
    
    // 2. Détection Littérature (Français, poésie)
    if (lowerText.contains('poème') ||
        lowerText.contains('conjugaison') ||
        lowerText.contains('verbe') ||
        lowerText.contains('grammaire') ||
        lowerText.contains('orthographe') ||
        lowerText.contains('littérature') ||
        lowerText.contains('adjectif')) {
      return 'Littérature';
    }
    
    // 3. Détection Humanités (Histoire, Géographie)
    if (lowerText.contains('histoire') ||
        lowerText.contains('guerre') ||
        lowerText.contains('siècle') ||
        lowerText.contains('géographie') ||
        lowerText.contains('climat') ||
        lowerText.contains('carte') ||
        lowerText.contains('afrique')) {
      return 'Humanités';
    }
    
    // 4. Détection Langues (Anglais, etc.)
    if (lowerText.contains('english') ||
        lowerText.contains('vocabulary') ||
        lowerText.contains('translate') ||
        lowerText.contains('pronoun')) {
      return 'Langues';
    }
    
    return 'Autre';
  }

  Future<void> _loadSubjects() async {
    final subjects = await DatabaseHelper.instance.getAllSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        final detected = _detectSubject(widget.ocrText);
        if (subjects.any((s) => s['label'] == detected)) {
          _selectedSubject = detected;
        } else if (subjects.isNotEmpty) {
          _selectedSubject = subjects.first['label'] as String;
        }
      });
    }
  }

  void _startGeneration() {
    setState(() {
      _isConfiguring = false;
    });

    // Progression visuelle des étapes
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentStep < 3) {
          _currentStep++;
        } else {
          _stepTimer?.cancel();
          if (_aiFinished && !_isRedirecting) {
            _autoSaveAndRedirect();
          }
        }
      });
    });

    _generate();
  }

  Future<void> _generate() async {
    final results = await _aiService.generateFlashcards(
      text: widget.ocrText,
      subject: _selectedSubject,
      level: _selectedLevel,
    );
    if (mounted) {
      setState(() {
        _flashcards = results;
        _aiFinished = true;
        
        // Si les étapes visuelles sont déjà finies, on redirige
        if (_currentStep >= 3 && !_isRedirecting) {
          _autoSaveAndRedirect();
        }
      });
    }
  }

  Future<void> _autoSaveAndRedirect() async {
    if (_isRedirecting) return;
    setState(() => _isRedirecting = true);

    if (_flashcards.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Désolé, l'IA n'a pas pu générer de fiches pour ce contenu."))
        );
      }
      return;
    }

    // Titre automatique basé sur le début du texte
    String title = 'Nouveau Deck';
    if (widget.ocrText.isNotEmpty) {
      title = widget.ocrText.split('\n').first.trim();
      if (title.length > 35) title = '${title.substring(0, 35)}...';
    }

    final String deckUuid = _uuid.v4();

    try {
      // On utilise le Repository directement pour attendre la fin de l'insertion
      // Cela garantit que FlashcardStudyScreen trouvera les cartes
      final repository = context.read<DeckRepositoryImpl>();
      await repository.createDeck(
        title,
        _selectedSubject,
        _selectedLevel,
        cards: _flashcards,
        uuid: deckUuid,
      );

      // On notifie le Bloc pour rafraîchir la liste en arrière-plan
      context.read<DeckBloc>().add(const LoadDecks());
      // On recharge aussi le profil et les activités récentes
      context.read<UserBloc>().add(LoadUserProfile());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardStudyScreen(
              deckTitle: title,
              deckUuid: deckUuid,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRedirecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la sauvegarde : $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConfiguring) {
      return _buildConfigUI();
    }
    return _buildLoadingUI();
  }

  Widget _buildConfigUI() {
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
          'Créer des flashcards',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Personnaliser la génération',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Sélectionne la matière et ton niveau pour que l'IA Kalan crée des questions parfaitement adaptées.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Label Matière
                    const Text(
                      'MATIÈRE DU COURS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF888888),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Grille des matières
                    _subjects.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _subjects.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.2,
                            ),
                            itemBuilder: (context, index) {
                              final sub = _subjects[index];
                              final label = sub['label'] as String;
                              final color = Color(sub['color'] as int);
                              final bgColor = Color(sub['bg_color'] as int);
                              final isSelected = _selectedSubject == label;
                              
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSubject = label),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? bgColor : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? color : const Color(0xFFE0E0E0),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected ? color : color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          IconData(sub['icon_code'] as int, fontFamily: 'MaterialIcons'),
                                          color: isSelected ? Colors.white : color,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? color : const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 28),
                    
                    // Label Niveau
                    const Text(
                      'NIVEAU SCOLAIRE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF888888),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Liste des niveaux
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _levels.length,
                        itemBuilder: (context, index) {
                          final lvl = _levels[index];
                          final isSelected = _selectedLevel == lvl;
                          
                          return GestureDetector(
                            onTap: () => setState(() => _selectedLevel = lvl),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF2D6A2D) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF2D6A2D) : const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  lvl,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : const Color(0xFF666666),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bouton de validation en bas
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: _startGeneration,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D6A2D),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D6A2D).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Générer mes flashcards',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('🪄', style: GoogleFonts.notoEmoji(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF8),
      body: SafeArea(
        child: Stack(
          children: [
            // Icônes de fond
            Positioned(top: 50, left: 40, child: Opacity(opacity: 0.1, child: const Text('🌿', style: TextStyle(fontSize: 48)))),
            Positioned(top: 120, right: 50, child: Opacity(opacity: 0.1, child: const Text('🌍', style: TextStyle(fontSize: 40)))),
            Positioned(bottom: 150, left: 60, child: Opacity(opacity: 0.1, child: const Text('📐', style: TextStyle(fontSize: 44)))),
            Positioned(bottom: 80, right: 70, child: Opacity(opacity: 0.1, child: const Text('🧪', style: TextStyle(fontSize: 48)))),
            
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  const Text(
                    'Génération en cours...',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary, fontFamily: 'Plus Jakarta Sans'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "L'IA KALAN transforme ton cours en succès",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  
                  // Loader
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RotationTransition(
                            turns: _rotationController,
                            child: SizedBox(
                              width: 170,
                              height: 170,
                              child: CustomPaint(painter: DashedCirclePainter(color: AppColors.primary.withOpacity(0.4))),
                            ),
                          ),
                          ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
                            child: Container(
                              width: 110, height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 20, spreadRadius: 8, offset: const Offset(0, 4))],
                                border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 1),
                              ),
                              child: Center(
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/kalan_logo.png', width: 70, height: 70, fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.forest, color: AppColors.primary, size: 54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Étapes
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepItem(0, "Analyse du texte (OCR)"),
                        const SizedBox(height: 12),
                        _buildStepItem(1, "Extraction des idées clés"),
                        const SizedBox(height: 12),
                        _buildStepItem(2, "Création des flashcards"),
                        const SizedBox(height: 12),
                        _buildStepItem(3, "Lancement de l'étude"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  if (_isRedirecting)
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))
                  else
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 32),
                        child: Text('ANNULER LA GÉNÉRATION', style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title) {
    bool isCompleted = _currentStep > stepIndex;
    bool isActive = _currentStep == stepIndex;
    Color textColor = isCompleted ? Colors.grey.shade700 : isActive ? AppColors.primary : Colors.grey.shade400;
    FontWeight textWeight = isActive || isCompleted ? FontWeight.bold : FontWeight.normal;
    double opacity = isActive || isCompleted ? 1.0 : 0.3;

    return Opacity(
      opacity: opacity,
      child: Row(
        children: [
          if (isCompleted)
            Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(0xFF2E7D32), shape: BoxShape.circle), child: const Center(child: Icon(Icons.check, color: Colors.white, size: 13)))
          else if (isActive)
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: const Color(0xFFEAF3DE), shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 1.5)),
              child: Center(child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))),
            )
          else
            Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 1))),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, color: textColor, fontWeight: textWeight, fontFamily: 'Plus Jakarta Sans'))),
        ],
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  DashedCirclePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double radius = width / 2;
    final Paint paint = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final double circumference = 2 * 3.14159 * radius;
    final double dashWidth = 8, dashSpace = 8;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashWidth + dashSpace) / circumference) * 2 * 3.14159;
      final double sweepAngle = (dashWidth / circumference) * 2 * 3.14159;
      canvas.drawArc(Rect.fromCircle(center: Offset(width / 2, size.height / 2), radius: radius), startAngle, sweepAngle, false, paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
