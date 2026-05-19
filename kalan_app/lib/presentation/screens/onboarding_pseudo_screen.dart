import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:kalan_app/data/local/database_helper.dart';
import 'package:kalan_app/data/models/user_model.dart';
import 'package:kalan_app/data/remote/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/kalan_button.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class OnboardingPseudoScreen extends StatefulWidget {
  final Map<String, dynamic>? registrationData;

  const OnboardingPseudoScreen({
    super.key,
    this.registrationData,
  });

  @override
  State<OnboardingPseudoScreen> createState() => _OnboardingPseudoScreenState();
}

class _OnboardingPseudoScreenState extends State<OnboardingPseudoScreen> {
  final TextEditingController _pseudoController = TextEditingController();
  int _selectedAvatar = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackgroundPattern(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildLogo(),
                  const SizedBox(height: 35),
                  const Text(
                    'Choisis ton pseudo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'C\'est avec ce pseudo que tu seras reconnu(e) par les autres élèves.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputBox('Ton pseudo'),
                  const SizedBox(height: 30),
                  const Text(
                    'Choisis ton avatar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'C\'est l\'image qui te représentera dans KALAN.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildAvatarGrid(),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        KalanButton(
                          text: 'Commencer mon aventure',
                          onPressed: _handleStartAventure,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            'Déjà un compte ? Connecte-toi ici',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.05,
        child: Image.asset(
          'assets/images/kalan_logo.png',
          repeat: ImageRepeat.repeat,
          scale: 10,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/kalan_logo.png',
      width: 160,
      height: 160,
      fit: BoxFit.contain,
    );
  }


  Widget _buildInputBox(String hint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      child: TextField(
        controller: _pseudoController,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87),
      ),
    );
  }

  Widget _buildAvatarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final avatarNum = index + 1;
        final isSelected = _selectedAvatar == avatarNum;
        return GestureDetector(
          onTap: () => setState(() => _selectedAvatar = avatarNum),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    width: isSelected ? 3 : 2.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: AppColors.primary.withOpacity(0.22), blurRadius: 6, spreadRadius: 2)]
                      : [],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/avatars/avatar$avatarNum.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleStartAventure() async {
    final pseudo = _pseudoController.text.trim();
    if (pseudo.length < 3 || pseudo.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le pseudo doit faire entre 3 et 20 caractères')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Vérification d'unicité locale (SQLite)
      final existingLocal = await DatabaseHelper.instance.getUserByPseudo(pseudo);
      if (existingLocal != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ce pseudo est déjà pris localement !'), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      // 2. Vérification d'unicité distante (Supabase)
      try {
        final existingRemote = await SupabaseService.client
            .from('users')
            .select('uuid')
            .eq('pseudo', pseudo)
            .maybeSingle();
        if (existingRemote != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ce pseudo est déjà pris, choisis-en un autre !'), backgroundColor: Colors.red),
            );
            setState(() => _isLoading = false);
          }
          return;
        }
      } catch (e) {
        debugPrint('Erreur vérification pseudo en ligne (mode hors-ligne probable): $e');
      }

      // 3. Générer UUID local
      final uuid = const Uuid().v4();

      final userModel = UserModel(
        uuid: uuid,
        pseudo: pseudo,
        avatarId: _selectedAvatar,
        isGuest: false,
        createdAt: DateTime.now(),
      );

      // 4. Sauvegarde locale SQLite
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      await db.insert('users', userModel.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      // Enregistrer l'ID de l'utilisateur actif
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_uuid', uuid);

      // 5. Sauvegarde Supabase (Profil utilisateur)
      try {
        await SupabaseService.client.from('users').upsert(userModel.toSupabaseJson());
      } catch (e) {
        debugPrint('Erreur upsert Supabase: $e');
        // Mode hors-ligne : les donnees seront synchronisees plus tard
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
