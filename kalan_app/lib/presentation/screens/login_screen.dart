import 'package:flutter/material.dart';
import 'package:kalan_app/data/local/database_helper.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/kalan_button.dart';
import 'home_screen.dart';
import 'onboarding_pseudo_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _pseudoController = TextEditingController();
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
                  const SizedBox(height: 60),
                  _buildLogo(),
                  const SizedBox(height: 60),
                  Text(
                    'Bon retour !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connecte-toi avec ton pseudo pour continuer ton aventure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A7A58),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildInputBox('Ton pseudo'),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    KalanButton(
                      text: 'Se connecter',
                      onPressed: _handleLogin,
                    ),
                  const SizedBox(height: 40),
                  _buildRegisterLink(),
                ],
              ),
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
      width: 180,
      height: 180,
      fit: BoxFit.contain,
    );
  }

  Widget _buildInputBox(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8CFBA), width: 2),
      ),
      child: TextField(
        controller: _pseudoController,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFC0B080), fontWeight: FontWeight.w600),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF3A2810)),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OnboardingPseudoScreen(),
          ),
        );
      },
      child: Text(
        'Pas encore de compte ? Inscris-toi ici',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final pseudo = _pseudoController.text.trim();
    if (pseudo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entre ton pseudo')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userMap = await DatabaseHelper.instance.getUserByPseudo(pseudo);
      if (userMap != null) {
        // Enregistrer l'ID de l'utilisateur actif
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_uuid', userMap['uuid']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pseudo inconnu, crée un compte')),
          );
        }
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
