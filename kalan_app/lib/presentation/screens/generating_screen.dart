import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:kalan_app/presentation/blocs/deck/deck_bloc.dart';
import 'package:kalan_app/presentation/blocs/deck/deck_event.dart';
import 'package:kalan_app/presentation/blocs/user/user_bloc.dart';
import 'package:kalan_app/presentation/blocs/user/user_state.dart';
import '../../core/constants/app_colors.dart';
import '../../data/local/database_helper.dart';
import '../../services/local_ai_service.dart';
import 'flashcard_study_screen.dart';

class GeneratingScreen extends StatefulWidget {
  final String ocrText;
  const GeneratingScreen({super.key, required this.ocrText});

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  final LocalAIService _aiService = LocalAIService();
  List<Map<String, String>> _flashcards = [];
  bool _isGenerating = true;
  final TextEditingController _titleController = TextEditingController();
  String _selectedSubject = 'SVT';
  String _selectedLevel = '3ème';
  bool _isPublic = false;
  List<String> _subjectNames = ['SVT', 'Mathématiques', 'Physique-Chimie', 'Histoire-Géo', 'Anglais', 'Français'];

  @override
  void initState() {
    super.initState();
    _generate();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await DatabaseHelper.instance.getAllSubjects();
    if (mounted && subjects.isNotEmpty) {
      setState(() {
        _subjectNames = subjects.map((s) => s['label'] as String).toList();
        if (!_subjectNames.contains(_selectedSubject)) {
          _selectedSubject = _subjectNames.first;
        }
      });
    }
  }

  Future<void> _generate() async {
    final results = await _aiService.generateFlashcards(
      text: widget.ocrText,
      subject: _selectedSubject,
      level: _selectedLevel,
      count: 5,
    );
    if (mounted) {
      setState(() {
        _flashcards = results;
        _isGenerating = false;
        if (widget.ocrText.isNotEmpty) {
          _titleController.text = widget.ocrText.split('\n').first;
          if (_titleController.text.length > 50) {
            _titleController.text = _titleController.text.substring(0, 50);
          }
        }
      });
    }
  }

  Future<void> _saveDeck() async {
    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoaded) return;

    final userId = userState.profile['uuid'];
    final deckUuid = const Uuid().v4();

    final db = await DatabaseHelper.instance.database;
    await db.insert('decks', {
      'uuid': deckUuid,
      'user_id': userId,
      'title': _titleController.text.isEmpty ? 'Nouveau Deck' : _titleController.text,
      'subject': _selectedSubject,
      'level': _selectedLevel,
      'is_public': _isPublic ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });

    for (var card in _flashcards) {
      await db.insert('flashcards', {
        'uuid': const Uuid().v4(),
        'deck_id': deckUuid,
        'question': card['question'],
        'answer': card['answer'],
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    if (mounted) {
      context.read<DeckBloc>().add(const LoadDecks());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FlashcardStudyScreen(
            deckTitle: _titleController.text,
            deckUuid: deckUuid,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGenerating) {
      return _buildLoadingState();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirmer le Deck'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeckInfoSection(),
            SizedBox(height: 24),
            Text('Flashcards générées (${_flashcards.length})', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _buildFlashcardsList(),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveDeck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Sauvegarder le Deck', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCulturalLoader(),
              SizedBox(height: 32),
              Text(
                'KALAN réfléchit...',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Génération des flashcards en cours...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCulturalLoader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 10),
      builder: (context, value, child) {
        IconData icon = Icons.eco;
        if (value > 0.8) icon = Icons.forest;
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary, size: 50 * (0.5 + value * 0.5)),
        );
      },
    );
  }

  Widget _buildDeckInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Titre du Deck', border: OutlineInputBorder()),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                  items: _subjectNames
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSubject = v!),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLevel,
                  decoration: const InputDecoration(labelText: 'Niveau', border: OutlineInputBorder()),
                  items: ['6ème', '5ème', '4ème', '3ème', '2nde', '1ère', 'Terminale', 'Autre']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLevel = v!),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Rendre ce deck public'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Flashcard #${index + 1}', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => setState(() => _flashcards.removeAt(index)),
                  ),
                ],
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Question'),
                controller: TextEditingController(text: _flashcards[index]['question']),
                onChanged: (v) => _flashcards[index]['question'] = v,
              ),
              SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(labelText: 'Réponse'),
                controller: TextEditingController(text: _flashcards[index]['answer']),
                onChanged: (v) => _flashcards[index]['answer'] = v,
              ),
            ],
          ),
        );
      },
    );
  }
}
