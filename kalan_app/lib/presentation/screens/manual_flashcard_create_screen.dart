import 'package:flutter/material.dart';
import '../../data/local/database_helper.dart';
import 'package:uuid/uuid.dart';

class ManualFlashcardCreateScreen extends StatefulWidget {
  final String extractedText;

  const ManualFlashcardCreateScreen({super.key, required this.extractedText});

  @override
  State<ManualFlashcardCreateScreen> createState() => _ManualFlashcardCreateScreenState();
}

class _ManualFlashcardCreateScreenState extends State<ManualFlashcardCreateScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  
  bool _isSaving = false;
  final Uuid _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer tes fiches')),
      body: Row(
        children: [
          // Panneau de gauche : Texte extrait (lecture seule)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  const Text('Texte extrait (OCR) :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(widget.extractedText),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Panneau de droite : Éditeur
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titre du Deck')),
                  const SizedBox(height: 16),
                  TextField(controller: _questionController, decoration: const InputDecoration(labelText: 'Question'), maxLines: 2),
                  const SizedBox(height: 16),
                  TextField(controller: _answerController, decoration: const InputDecoration(labelText: 'Réponse'), maxLines: 3),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveFlashcard,
                    child: _isSaving ? const CircularProgressIndicator() : const Text('Enregistrer la fiche'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFlashcard() async {
    setState(() => _isSaving = true);
    
    try {
      final String deckUuid = _uuid.v4();
      final deckData = {
        'uuid': deckUuid,
        'user_id': 'local_user', // À ajuster selon gestion utilisateur
        'title': _titleController.text,
        'subject': 'Autre',
        'is_synced': 0, // Flag pour synchro ultérieure
      };
      
      final cardData = {
        'uuid': _uuid.v4(),
        'deck_id': deckUuid,
        'question': _questionController.text,
        'answer': _answerController.text,
        'is_synced': 0,
      };
      
      await DatabaseHelper.instance.insertDeck(deckData);
      await DatabaseHelper.instance.insertFlashcard(cardData);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fiche enregistrée localement !')));
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
