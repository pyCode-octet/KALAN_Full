import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class GemmaService {
  static const MethodChannel _channel = MethodChannel('com.kalan.gemma');
  bool _isLoaded = false;
  
  Future<void> loadModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/models/gemma-2b-it-q4_k_m.gguf';
    
    try {
      await _channel.invokeMethod('loadModel', {
        'modelPath': modelPath,
        'nCtx': 2048,
        'nThreads': 4,
      });
      _isLoaded = true;
    } catch (e) {
      print('Erreur chargement modèle Gemma: $e');
      rethrow;
    }
  }
  
  Future<String> generateText(String prompt, {int maxTokens = 512}) async {
    if (!_isLoaded) await loadModel();
    
    try {
      final result = await _channel.invokeMethod('generate', {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': 0.7,
        'stopSequences': ['</s>', 'Human:', 'Assistant:'],
      });
      return result as String;
    } catch (e) {
      print('Erreur génération texte Gemma: $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, String>>> generateFlashcards({
    required String text,
    required String subject,
    required String level,
    int count = 5,
  }) async {
    final prompt = '''
Tu es un professeur de $subject pour élèves de $level en Afrique.
Crée exactement $count flashcards au format JSON.
Questions courtes (max 10 mots), réponses courtes (max 15 mots).
Format strict :
[
  {"q":"Question 1","a":"Réponse 1"},
  {"q":"Question 2","a":"Réponse 2"}
]

Texte du cours :
$text
''';

    final raw = await generateText(prompt, maxTokens: 1024);
    return _parseFlashcards(raw);
  }
  
  List<Map<String, String>> _parseFlashcards(String raw) {
    try {
      // Extraire le JSON de la réponse
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']') + 1;
      if (jsonStart == -1 || jsonEnd == 0) throw Exception('Pas de JSON trouvé');
      
      final jsonStr = raw.substring(jsonStart, jsonEnd);
      final List<dynamic> parsed = jsonDecode(jsonStr);
      
      return parsed.map((item) => {
        'question': item['q']?.toString() ?? '',
        'answer': item['a']?.toString() ?? '',
      }).toList();
    } catch (e) {
      // Fallback simple : parser par lignes si le JSON échoue
      return _fallbackParse(raw);
    }
  }

  List<Map<String, String>> _fallbackParse(String raw) {
    final List<Map<String, String>> cards = [];
    final lines = raw.split('\n');
    String? currentQ;
    
    for (var line in lines) {
      if (line.contains('?') || line.startsWith('Q:')) {
        currentQ = line.replaceFirst('Q:', '').trim();
      } else if (currentQ != null && (line.contains(':') || line.startsWith('R:'))) {
        cards.add({
          'question': currentQ,
          'answer': line.replaceFirst('R:', '').trim(),
        });
        currentQ = null;
        if (cards.length >= 5) break;
      }
    }
    return cards;
  }

  Future<void> unloadModel() async {
    if (_isLoaded) {
      await _channel.invokeMethod('unloadModel');
      _isLoaded = false;
    }
  }
}
