import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../ai/gemma_service.dart';
import 'connectivity_service.dart';

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  final GemmaService _gemmaService = GemmaService();
  final ConnectivityService _connectivityService = ConnectivityService();

  static String get _hfToken => dotenv.env['HF_TOKEN'] ?? '';
  static const String _hfBaseUrl = 'https://router.huggingface.co/v1/chat/completions';
  static const List<String> _models = [
    'Qwen/Qwen2.5-72B-Instruct',
    'Qwen/Qwen2.5-7B-Instruct',
  ];

  Future<List<Map<String, String>>> generateFlashcards({
    required String text,
    String subject = 'Général',
    String level = 'Scolaire',
  }) async {
    final isOnline = await _connectivityService.isOnline();
    
    if (isOnline) {
      debugPrint('Mode Online : Utilisation de HuggingFace API');
      try {
        return await _generateOnline(text, subject, level);
      } catch (e) {
        debugPrint('Erreur HuggingFace API, basculement sur l\'IA locale : $e');
        return await _generateOffline(text, subject, level);
      }
    } else {
      debugPrint('Mode Offline : Utilisation de l\'IA locale (Gemma)');
      return await _generateOffline(text, subject, level);
    }
  }

  Future<List<Map<String, String>>> _generateOnline(String text, String subject, String level) async {
    final prompt = _buildFlashcardPrompt(text, subject, level);
    
    for (final model in _models) {
      try {
        debugPrint('Tentative avec le modèle: $model');
        
        final response = await http.post(
          Uri.parse(_hfBaseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_hfToken',
          },
          body: jsonEncode({
            'model': model,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.7,
            'max_tokens': 1024,
          }),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 503) {
          debugPrint('Modèle $model en chargement, essai du suivant...');
          continue;
        }

        if (response.statusCode == 429) {
          debugPrint('Quota dépassé pour $model, essai du suivant...');
          continue;
        }

        if (response.statusCode != 200) {
          debugPrint('Erreur $model: ${response.statusCode} - ${response.body}');
          continue;
        }

        final data = jsonDecode(response.body);
        final rawText = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        
        debugPrint('Réponse HuggingFace reçue via $model (${rawText.length} caractères)');
        if (rawText.isNotEmpty) {
          return _parseFlashcards(rawText);
        }
        continue;
      } catch (e) {
        debugPrint('Erreur avec $model: $e');
        continue;
      }
    }
    

    throw Exception('Tous les modèles HuggingFace ont échoué');
  }

  Future<List<Map<String, String>>> _generateOffline(String text, String subject, String level) async {
    try {
      if (text.trim().length < 10) {
        return _fallbackHeuristic(text);
      }

      final prompt = _buildFlashcardPrompt(text, subject, level);
      final rawResponse = await _gemmaService.generateText(prompt, maxTokens: 1024);
      return _parseFlashcards(rawResponse);
    } catch (e) {
      debugPrint('Gemma Offline Error: $e');
      return _fallbackHeuristic(text);
    }
  }

  String _buildFlashcardPrompt(String text, String subject, String level) {
    return '''Tu es un professeur de $subject pour élèves de $level en Afrique.
Crée exactement 5 flashcards basées sur le texte ci-dessous.
Format JSON strict :
[
  {"question": "La question ici", "answer": "La réponse ici"}
]

Texte :
$text
''';
  }

  List<Map<String, String>> _parseFlashcards(String raw) {
    try {
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']') + 1;
      if (jsonStart == -1 || jsonEnd == 0) throw Exception('Pas de JSON trouvé');
      
      final jsonStr = raw.substring(jsonStart, jsonEnd);
      final List<dynamic> parsed = jsonDecode(jsonStr);
      
      // Filtrer les cartes vides
      final cards = parsed.map((item) => {
        'question': (item['question'] ?? item['q'] ?? '').toString().trim(),
        'answer': (item['answer'] ?? item['a'] ?? '').toString().trim(),
      })
      .where((card) => card['question']!.isNotEmpty && card['answer']!.isNotEmpty)
      .toList();
      
      debugPrint('✅ Parsing réussi: ${cards.length}/${parsed.length} cartes valides');
      return cards;
    } catch (e) {
      debugPrint('❌ Parsing error, using fallback parser: $e');
      return _regexFallbackParse(raw);
    }
  }

  List<Map<String, String>> _regexFallbackParse(String raw) {
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final List<Map<String, String>> cards = [];
    for (var line in lines) {
      final parts = line.split(RegExp(r'\?|:'));
      if (parts.length >= 2) {
        cards.add({
          'question': parts[0].trim().replaceAll(RegExp(r'^[\d\.\-\s]+'), '') + ' ?',
          'answer': parts.sublist(1).join(' ').trim(),
        });
      }
      if (cards.length >= 5) break;
    }
    return cards.isEmpty ? _fallbackHeuristic(raw) : cards;
  }

  List<Map<String, String>> _fallbackHeuristic(String text) {
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.trim().length > 15).toList();
    
    if (sentences.isEmpty) {
      return [
        {'question': 'De quoi parle ce texte ?', 'answer': text.length > 50 ? text.substring(0, 50) + '...' : text}
      ];
    }

    return sentences.take(5).map((s) {
      final words = s.trim().split(' ');
      if (words.length > 6) {
        return {
          'question': 'Explique : ${words.take(3).join(' ')}...',
          'answer': s.trim(),
        };
      }
      return {
        'question': 'Que retenir de cette partie ?',
        'answer': s.trim(),
      };
    }).toList();
  }

  Future<void> unloadModel() async {
    await _gemmaService.unloadModel();
  }
}
