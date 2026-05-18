import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../ai/gemma_service.dart';
import 'connectivity_service.dart';
import '../data/remote/supabase_service.dart';

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  final GemmaService _gemmaService = GemmaService();
  final ConnectivityService _connectivityService = ConnectivityService();

  Future<List<Map<String, String>>> generateFlashcards({
    required String text,
    String subject = 'Général',
    String level = 'Scolaire',
  }) async {
    final isOnline = await _connectivityService.isOnline();
    
    if (isOnline) {
      debugPrint('Mode Online : Utilisation de l\'IA Cloud via Supabase');
      try {
        return await _generateOnline(text, subject, level);
      } catch (e) {
        debugPrint('Erreur IA Cloud, basculement sur l\'IA locale : $e');
        return await _generateOffline(text, subject, level);
      }
    } else {
      debugPrint('Mode Offline : Utilisation de l\'IA locale (Gemma)');
      return await _generateOffline(text, subject, level);
    }
  }

  Future<List<Map<String, String>>> _generateOnline(String text, String subject, String level) async {
    final response = await SupabaseService.client.functions.invoke(
      'generate-flashcards',
      body: {
        'text': text,
        'subject': subject,
        'level': level,
      },
    );

    if (response.status != 200) {
      throw Exception('Erreur Edge Function: ${response.status}');
    }

    final List<dynamic> flashcards = response.data['flashcards'];
    return flashcards.map((f) => {
      'question': f['question']?.toString() ?? f['q']?.toString() ?? '',
      'answer': f['answer']?.toString() ?? f['a']?.toString() ?? '',
    }).toList();
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
      
      return parsed.map((item) => {
        'question': (item['question'] ?? item['q'] ?? '').toString(),
        'answer': (item['answer'] ?? item['a'] ?? '').toString(),
      }).toList();
    } catch (e) {
      debugPrint('Parsing error, using fallback parser: $e');
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
