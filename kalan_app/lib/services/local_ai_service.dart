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
    // 1. Tenter d'abord la génération en ligne qui produit des fiches de qualité exceptionnelle
    debugPrint('Mode Hybride : Tentative de génération en ligne via HuggingFace API...');
    try {
      final onlineResults = await _generateOnline(text, subject, level).timeout(const Duration(seconds: 15));
      if (onlineResults.isNotEmpty) {
        debugPrint('✅ Fiches générées avec succès en ligne (HuggingFace)');
        return onlineResults;
      }
    } catch (e) {
      debugPrint('⚠️ Inaccessible en ligne (pas d\'internet ou erreur quota), basculement vers l\'IA locale : $e');
    }

    // 2. Si échec ou hors ligne, utiliser l'IA locale Gemma
    debugPrint('Mode Offline : Utilisation de l\'IA locale (Gemma)...');
    return await _generateOffline(text, subject, level);
  }

  Future<List<Map<String, String>>> _generateOnline(String text, String subject, String level) async {
    final prompt = _buildFlashcardPrompt(text, subject, level, isOnline: true);
    
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

      // Tronquer le texte pour utiliser pleinement la fenêtre de contexte de Gemma 3 1B (max 8000 car.)
      final truncatedText = text.length > 8000 ? text.substring(0, 8000) + '...' : text;

      final prompt = _buildFlashcardPrompt(truncatedText, subject, level, isOnline: false);
      final rawResponse = await _gemmaService.generateText(prompt, maxTokens: 1024);
      return _parseFlashcards(rawResponse);
    } catch (e) {
      debugPrint('Gemma Offline Error: $e');
      return _fallbackHeuristic(text);
    }
  }

  String _buildFlashcardPrompt(String text, String subject, String level, {required bool isOnline}) {
    if (isOnline) {
      return '''Tu es un professeur de $subject pour élèves de $level en Afrique.
Crée exactement 5 flashcards basées sur le texte ci-dessous.
Format JSON strict :
[
  {"question": "La question ici", "answer": "La réponse ici"}
]

Texte :
$text
''';
    } else {
      // Prompt optimisé pour Gemma 3 1B (contexte en premier, amorce à la fin)
      return '''Texte du cours :
$text

Consigne : Génère exactement 5 questions et réponses en français sur le texte ci-dessus.
Format à suivre :
Q1: Question 1
R1: Réponse 1
Q2: Question 2
R2: Réponse 2
Q3: Question 3
R3: Réponse 3
Q4: Question 4
R4: Réponse 4
Q5: Question 5
R5: Réponse 5

Q1:''';
    }
  }

  List<Map<String, String>> _parseFlashcards(String raw) {
    // 1. Tenter d'abord de parser le format JSON (utilisé en ligne)
    try {
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = raw.substring(jsonStart, jsonEnd);
        final List<dynamic> parsed = jsonDecode(jsonStr);
        final cards = parsed.map((item) => {
          'question': (item['question'] ?? item['q'] ?? '').toString().trim(),
          'answer': (item['answer'] ?? item['a'] ?? '').toString().trim(),
        })
        .where((card) => card['question']!.isNotEmpty && card['answer']!.isNotEmpty)
        .toList();
        
        if (cards.isNotEmpty) {
          debugPrint('✅ Parsing JSON réussi : ${cards.length} cartes valides');
          return cards;
        }
      }
    } catch (e) {
      debugPrint('Format JSON absent ou invalide, essai du parser de secours...');
    }

    // 2. Parser le format textuel Q/R de secours (idéal pour le modèle offline)
    try {
      final List<Map<String, String>> cards = [];
      // Expressions régulières robustes pour capturer les blocs Q: et R:
      final qRegExp = RegExp(r'(?:Q\d*|Question\d*)\s*[:：]\s*(.*?)(?=(?:R\d*|Rép\w*\d*)\s*[:：]|$)', caseSensitive: false, dotAll: true);
      final aRegExp = RegExp(r'(?:R\d*|Rép\w*\d*)\s*[:：]\s*(.*?)(?=(?:Q\d*|Question\d*)\s*[:：]|$)', caseSensitive: false, dotAll: true);
      
      final qMatches = qRegExp.allMatches(raw).toList();
      final aMatches = aRegExp.allMatches(raw).toList();
      
      final count = qMatches.length < aMatches.length ? qMatches.length : aMatches.length;
      for (var i = 0; i < count; i++) {
        final qText = qMatches[i].group(1)?.trim() ?? '';
        final aText = aMatches[i].group(1)?.trim() ?? '';
        if (qText.isNotEmpty && aText.isNotEmpty) {
          cards.add({
            'question': qText,
            'answer': aText,
          });
        }
      }
      
      if (cards.isNotEmpty) {
        debugPrint('✅ Parsing de secours Q/R réussi : ${cards.length} cartes valides');
        return cards;
      }
    } catch (e) {
      debugPrint('Échec du parser Q/R : $e');
    }

    // 3. Fallback sur la méthode heuristique intelligente si tout le reste a échoué
    debugPrint('⚠️ Aucun format détecté, utilisation de la méthode heuristique de définitions...');
    return _fallbackHeuristic(raw);
  }

  List<Map<String, String>> _fallbackHeuristic(String text) {
    // 1. Nettoyer le texte global
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 2. Découper en phrases valides
    final sentences = cleanText
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().length > 20 && s.trim().length < 250)
        .toList();
        
    if (sentences.isEmpty) {
      return [
        {
          'question': 'De quoi parle ce cours ?',
          'answer': text.length > 100 ? text.substring(0, 100).trim() + '...' : text.trim()
        }
      ];
    }

    // 3. Extraire les phrases qui définissent des concepts (est, sont, signifie, permet, etc.)
    final List<Map<String, String>> cards = [];
    final definitionKeywords = ['est ', 'sont ', 'signifie', 'définit', 'permet', 'concerne', 'sert à'];
    
    for (var sentence in sentences) {
      bool isDefinition = definitionKeywords.any((kw) => sentence.toLowerCase().contains(kw));
      if (isDefinition) {
        for (var kw in definitionKeywords) {
          final index = sentence.toLowerCase().indexOf(kw);
          // Le mot-clé doit être au milieu de la phrase
          if (index > 4 && index < sentence.length - 12) {
            final subject = sentence.substring(0, index).trim();
            final definition = sentence.substring(index + kw.length).trim();
            
            // Nettoyage du sujet (enlever les puces, tirets, numéros)
            final cleanSubject = subject.replaceAll(RegExp(r'^[\d\.\-\s•*+–—]+'), '').trim();
            
            if (cleanSubject.length > 2 && cleanSubject.length < 50 && definition.length > 12) {
              final capitalizedSubject = cleanSubject[0].toUpperCase() + cleanSubject.substring(1);
              final capitalizedDefinition = definition[0].toUpperCase() + definition.substring(1);
              
              cards.add({
                'question': 'Qu\'est-ce que : $capitalizedSubject ?',
                'answer': 'C\'${kw.trim()} $capitalizedDefinition',
              });
              break;
            }
          }
        }
      }
      if (cards.length >= 5) break;
    }

    // 4. Si pas assez de définitions grammaticales, compléter avec des phrases informatives plus propres
    if (cards.length < 5) {
      for (var sentence in sentences) {
        final cleanSentence = sentence.replaceAll(RegExp(r'^[\d\.\-\s•*+–—]+'), '').trim();
        if (cleanSentence.length > 35) {
          final alreadyAdded = cards.any((c) => c['answer'] == cleanSentence);
          if (!alreadyAdded) {
            final summaryTitle = cleanSentence.substring(0, cleanSentence.length > 50 ? 50 : cleanSentence.length).trim();
            cards.add({
              'question': 'Explique ce concept ou point clé :\n"$summaryTitle..." ?',
              'answer': cleanSentence,
            });
          }
        }
        if (cards.length >= 5) break;
      }
    }

    // 5. Ultime secours si le deck reste désespérément vide
    if (cards.isEmpty) {
      cards.add({
        'question': 'Quel est le sujet clé abordé dans ce document ?',
        'answer': cleanText.length > 150 ? cleanText.substring(0, 150) + '...' : cleanText,
      });
    }

    return cards;
  }

  Future<void> unloadModel() async {
    await _gemmaService.unloadModel();
  }
}
