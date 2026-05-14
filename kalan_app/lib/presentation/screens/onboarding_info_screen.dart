import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/remote/supabase_service.dart';
import '../widgets/kalan_button.dart';
import 'onboarding_pseudo_screen.dart';

class OnboardingInfoScreen extends StatefulWidget {
  const OnboardingInfoScreen({super.key});

  @override
  State<OnboardingInfoScreen> createState() => _OnboardingInfoScreenState();
}

class _OnboardingInfoScreenState extends State<OnboardingInfoScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  
  int? _selectedClassId;
  List<Map<String, dynamic>> _classes = [];
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final response = await SupabaseService.client
          .from('classes')
          .select()
          .order('display_order', ascending: true);
      
      if (mounted) {
        setState(() {
          _classes = List<Map<String, dynamic>>.from(response);
          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur fetch classes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mode hors-ligne : classes chargees localement')),
        );
        setState(() {
          _classes = [
            {'id': 1, 'name': '6eme'},
            {'id': 2, 'name': '5eme'},
            {'id': 3, 'name': '4eme'},
            {'id': 4, 'name': '3eme'},
            {'id': 5, 'name': '2nde'},
            {'id': 6, 'name': '1ere'},
            {'id': 7, 'name': 'Terminale'},
            {'id': 8, 'name': 'Autre'},
          ];
          _isLoadingClasses = false;
        });
      }
    }
  }

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
                  _buildProgressIndicator(),
                  const SizedBox(height: 35),
                  Text(
                    'Parle-nous un peu de toi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ces informations nous aideront à mieux personnaliser ton expérience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8A7A58),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputBox('Ton prénom', _firstNameController),
                  _buildInputBox('Ton nom', _lastNameController),
                  _buildInputBox('Nom de ton école', _schoolController),
                  _buildClassDropdown(),
                  const SizedBox(height: 20),
                  KalanButton(
                    text: 'Suivant',
                    onPressed: _handleNext,
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
              icon: Icon(Icons.arrow_back, color: AppColors.primary, size: 28),
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
    return Column(
      children: [
        Image.asset(
          'assets/images/kalan_logo.png',
          width: 94,
          height: 94,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
        Text(
          'KALAN',
          style: TextStyle(
            fontSize: 40,
            color: AppColors.primary,
            letterSpacing: 5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          'Le savoir qui grandit avec toi',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStep(1, 'Infos', true),
        _buildLine(),
        _buildStep(2, 'Pseudo', false),
        _buildLine(),
        _buildStep(3, 'Avatar', false),
      ],
    );
  }

  Widget _buildStep(int step, String label, bool active) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : const Color(0xFFEDE7DB),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step.toString(),
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6A5A38),
          ),
        ),
      ],
    );
  }

  Widget _buildLine() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 22, left: 4, right: 4),
      color: const Color(0xFFD8CFBF),
    );
  }

  Widget _buildInputBox(String hint, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8CFBA), width: 2),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFC0B080), fontWeight: FontWeight.w600),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3A2810)),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8CFBA), width: 2),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedClassId,
        hint: Text(
          _isLoadingClasses ? 'Chargement...' : 'Ta classe',
          style: const TextStyle(color: Color(0xFFC0B080), fontWeight: FontWeight.w600, fontSize: 15),
        ),
        items: _classes.map((cls) {
          return DropdownMenuItem<int>(
            value: cls['id'],
            child: Text(
              cls['name'],
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3A2810)),
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedClassId = val),
        decoration: const InputDecoration(border: InputBorder.none),
        icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  void _handleNext() {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _schoolController.text.trim().isEmpty ||
        _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplis tous les champs')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingPseudoScreen(
          registrationData: {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'school_name': _schoolController.text.trim(),
            'class_id': _selectedClassId,
          },
        ),
      ),
    );
  }
}
