import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import 'home_dashboard.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'deck_list_screen.dart';
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
    const DeckListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE0D8CC), width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Accueil'),
                _navItem(1, Icons.library_books_outlined, Icons.library_books_rounded, 'Librairie'),
                _buildCenterButton(),
                _navItem(3, Icons.layers_outlined, Icons.layers_rounded, 'Decks'),
                _navItem(4, Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTap: () => _showCreateOptions(context),
      child: Container(
        width: 52,
        height: 52,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
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

                    if (result != null && result.files.single != null) {
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

  Widget _navItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? AppColors.primary : const Color(0xFFB0A89A),
              size: 22,
            ),
            SizedBox(height: 2),
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
