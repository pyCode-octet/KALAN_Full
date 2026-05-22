import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../ai/gemma_service.dart';
import '../ai/model_downloader.dart';
import 'connectivity_service.dart';

class LocalAIService {
  static final LocalAIService _instance = LocalAIService._internal();
  factory LocalAIService() => _instance;
  LocalAIService._internal();

  final GemmaService _gemmaService = GemmaService();

  static String get _hfToken => dotenv.env['HF_TOKEN'] ?? '';
  static const String _hfBaseUrl = 'https://router.huggingface.co/v1/chat/completions';
  static const List<String> _models = [
    'Qwen/Qwen2.5-72B-Instruct',
    'Qwen/Qwen2.5-7B-Instruct',
  ];

  /// true si internet + jeton HF configuré.
  Future<bool> canUseOnlineAI() async {
    if (!await ConnectivityService().isOnline()) return false;
    return _hfToken.trim().isNotEmpty;
  }

  Future<bool> isOfflineGemmaReady() => ModelDownloader.isModelDownloaded();

  Future<Map<String, dynamic>> generateFlashcards({
    required String text,
  }) async {
    final detectedSubject = _detectSubjectHeuristic(text);
    const level = 'Général';

    // 1. En ligne : Qwen via Hugging Face (meilleure qualité)
    if (await canUseOnlineAI()) {
      debugPrint('[KALAN AI] Mode en ligne (HuggingFace)...');
      try {
        final onlineResults = await _generateOnline(text, detectedSubject, level)
            .timeout(const Duration(seconds: 20));
        if (onlineResults.isNotEmpty) {
          debugPrint('[KALAN AI] ✅ Fiches générées en ligne');
          return {
            'subject': detectedSubject,
            'flashcards': onlineResults,
            'mode': 'online',
          };
        }
      } catch (e) {
        debugPrint('[KALAN AI] Échec en ligne, bascule offline : $e');
      }
    } else {
      debugPrint('[KALAN AI] Pas de réseau ou HF_TOKEN absent → mode offline');
    }

    // 2. Hors ligne : Gemma si installé
    final offline = await _generateOffline(text, detectedSubject, level);
    return {
      'subject': detectedSubject,
      'flashcards': offline.cards,
      'mode': offline.mode,
      if (offline.modelMissing) 'offlineModelMissing': true,
    };
  }

  String _detectSubjectHeuristic(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('fraction') || lowerText.contains('équation') || lowerText.contains('calculer') || lowerText.contains('géométrie') || lowerText.contains('triangle') || lowerText.contains('théorème') || lowerText.contains('nombre') || lowerText.contains('fonction')) {
      return 'Mathématiques';
    }
    if (lowerText.contains('cellule') || lowerText.contains('plante') || lowerText.contains('corps humain') || lowerText.contains('organe') || lowerText.contains('adn') || lowerText.contains('génétique') || lowerText.contains('reproduction')) {
      return 'SVT';
    }
    if (lowerText.contains('chimie') || lowerText.contains('physique') || lowerText.contains('atome') || lowerText.contains('molécule') || lowerText.contains('force') || lowerText.contains('vitesse') || lowerText.contains('pesanteur')) {
      return 'Physique-Chimie';
    }
    if (lowerText.contains('informatique') || lowerText.contains('ordinateur') || lowerText.contains('code') || lowerText.contains('programmation') || lowerText.contains('algorithme')) {
      return 'Informatique';
    }
    if (lowerText.contains('poème') || lowerText.contains('conjugaison') || lowerText.contains('verbe') || lowerText.contains('grammaire') || lowerText.contains('orthographe') || lowerText.contains('littérature') || lowerText.contains('adjectif') || lowerText.contains('français')) {
      return 'Français';
    }
    if (lowerText.contains('histoire') || lowerText.contains('guerre') || lowerText.contains('siècle') || lowerText.contains('géographie') || lowerText.contains('climat') || lowerText.contains('carte') || lowerText.contains('afrique')) {
      return 'Histoire-Géo';
    }
    if (lowerText.contains('english') || lowerText.contains('vocabulary') || lowerText.contains('translate') || lowerText.contains('pronoun')) {
      return 'Anglais';
    }
    return 'Autre';
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

  Future<({List<Map<String, String>> cards, String mode, bool modelMissing})> _generateOffline(
    String text,
    String subject,
    String level,
  ) async {
    if (text.trim().length < 10) {
      return (cards: _fallbackHeuristic(text), mode: 'heuristic', modelMissing: false);
    }

    final modelInstalled = await ModelDownloader.isModelDownloaded();
    if (!modelInstalled) {
      debugPrint('[KALAN AI] Modèle Gemma non installé → extracteur heuristique');
      return (
        cards: _fallbackHeuristic(text),
        mode: 'heuristic',
        modelMissing: true,
      );
    }

    try {
      debugPrint('[KALAN AI] Génération via Gemma 3 (offline)...');
      final truncatedText = text.length > 8000 ? '${text.substring(0, 8000)}...' : text;
      final prompt = _buildFlashcardPrompt(truncatedText, subject, level, isOnline: false);
      final rawResponse = await _gemmaService
          .generateText(prompt, maxTokens: 1024)
          .timeout(const Duration(seconds: 90));
      final parsed = _parseFlashcards(rawResponse);
      if (parsed.isNotEmpty) {
        debugPrint('[KALAN AI] ✅ ${parsed.length} fiches via Gemma');
        return (cards: parsed, mode: 'gemma', modelMissing: false);
      }
    } catch (e) {
      debugPrint('[KALAN AI] Erreur Gemma : $e');
    }

    debugPrint('[KALAN AI] Secours heuristique');
    return (cards: _fallbackHeuristic(text), mode: 'heuristic', modelMissing: false);
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
      // Prompt optimisé pour Gemma 3 1B (Few-shot prompting strict)
      return '''### Tâche
Génère exactement 5 questions et réponses en français sur le texte fourni.
Sois très concis.

### Exemples

Texte : La photosynthèse est le processus par lequel les plantes créent leur énergie grâce au soleil.
Q1: Quel est le processus utilisé par les plantes ?
R1: La photosynthèse.
Q2: Quelle est la source d'énergie des plantes ?
R2: Le soleil.

Texte : Le Nil est le plus long fleuve d'Afrique, traversant l'Égypte.
Q1: Quel est le plus long fleuve d'Afrique ?
R1: Le Nil.
Q2: Quel pays est traversé par le Nil ?
R2: L'Égypte.

### Texte actuel
$text

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
        final cards = parsed.map<Map<String, String>>((item) => {
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
      // Expressions régulières robustes pour capturer les blocs Q: et R/A:
      final qRegExp = RegExp(r'(?:Q\d*|Question\d*)\s*[:：]\s*(.*?)(?=(?:[RA]\d*|Rép\w*\d*|Answer\d*)\s*[:：]|$)', caseSensitive: false, dotAll: true);
      final aRegExp = RegExp(r'(?:[RA]\d*|Rép\w*\d*|Answer\d*)\s*[:：]\s*(.*?)(?=(?:Q\d*|Question\d*)\s*[:：]|$)', caseSensitive: false, dotAll: true);
      
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
    final List<Map<String, String>> cards = [];
    final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // 1. Découper en phrases valides de manière plus robuste
    final sentences = cleanText
        .split(RegExp(r'(?<=[.!?;\n])\s+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15)
        .toList();

    // 2. Extraire les phrases qui définissent des concepts (est, sont, signifie, permet, etc.)
    final definitionKeywords = ['est ', 'sont ', 'signifie', 'définit', 'permet', 'concerne', 'sert à', 'constitue'];
    for (var sentence in sentences) {
      bool isDefinition = definitionKeywords.any((kw) => sentence.toLowerCase().contains(kw));
      if (isDefinition) {
        for (var kw in definitionKeywords) {
          final index = sentence.toLowerCase().indexOf(kw);
          if (index > 3 && index < sentence.length - 10) {
            final subject = sentence.substring(0, index).trim();
            final definition = sentence.substring(index + kw.length).trim();
            
            // Nettoyage du sujet (enlever les puces, tirets, numéros)
            final cleanSubject = subject.replaceAll(RegExp(r'^[\d\.\-\s•*+–—]+'), '').trim();
            
            if (cleanSubject.length > 2 && cleanSubject.length < 60 && definition.length > 8) {
              final capitalizedSubject = cleanSubject[0].toUpperCase() + cleanSubject.substring(1);
              final capitalizedDefinition = definition[0].toUpperCase() + definition.substring(1);
              
              // Éviter les doublons
              final alreadyAdded = cards.any((c) => (c['question'] ?? '').contains(capitalizedSubject));
              if (!alreadyAdded) {
                cards.add({
                  'question': 'Qu\'est-ce que : $capitalizedSubject ?',
                  'answer': 'C\'${kw.trim()} $capitalizedDefinition',
                });
                break;
              }
            }
          }
        }
      }
      if (cards.length >= 5) break;
    }

    // 3. Si pas assez de définitions grammaticales, compléter avec des phrases informatives plus propres
    if (cards.length < 5) {
      for (var sentence in sentences) {
        final cleanSentence = sentence.replaceAll(RegExp(r'^[\d\.\-\s•*+–—]+'), '').trim();
        if (cleanSentence.length > 25) {
          final alreadyAdded = cards.any((c) => c['answer'] == cleanSentence || (c['question'] ?? '').contains(cleanSentence.substring(0, 10)));
          if (!alreadyAdded) {
            final summaryTitle = cleanSentence.substring(0, cleanSentence.length > 45 ? 45 : cleanSentence.length).trim();
            cards.add({
              'question': 'Explique ce concept ou point clé :\n"$summaryTitle..." ?',
              'answer': cleanSentence,
            });
          }
        }
        if (cards.length >= 5) break;
      }
    }

    // 4. Si nous n'avons toujours pas 5 cartes (texte trop court, par exemple), créer des questions génériques structurées
    if (cards.length < 5) {
      final String shortSummary = cleanText.length > 80 ? '${cleanText.substring(0, 80)}...' : cleanText;
      
      final genericTemplates = [
        (
          q: "Quel est le thème ou sujet principal abordé dans ce cours ?",
          a: "Ce cours traite principalement de : $shortSummary"
        ),
        (
          q: "Quelle est l'idée majeure à retenir de ce document ?",
          a: "L'idée majeure est de comprendre le concept suivant : $cleanText"
        ),
        (
          q: "Explique l'importance de ce sujet dans le cadre d'un examen.",
          a: "Ce sujet est fondamental car il pose les bases et le vocabulaire clé associés à : $shortSummary"
        ),
        (
          q: "Résume ce texte en un mot-clé ou expression essentielle.",
          a: "Le mot-clé essentiel est lié à : ${shortSummary.split(' ').take(3).join(' ')}"
        ),
        (
          q: "Quelle question peut poser le professeur sur ce texte ?",
          a: "Le professeur pourrait demander d'expliquer ou définir : $shortSummary"
        ),
      ];

      for (var template in genericTemplates) {
        if (cards.length >= 5) break;
        final alreadyAdded = cards.any((c) => c['question'] == template.q);
        if (!alreadyAdded) {
          cards.add({
            'question': template.q,
            'answer': template.a,
          });
        }
      }
    }

    // Sécurité absolue : S'assurer qu'il y a TOUJOURS exactement 5 cartes
    while (cards.length < 5) {
      cards.add({
        'question': 'Point clé additionnel ${cards.length + 1} de l\'étude',
        'answer': cleanText.length > 100 ? '${cleanText.substring(0, 100)}...' : cleanText,
      });
    }

    // Si par erreur on dépasse 5 cartes, tronquer
    if (cards.length > 5) {
      return cards.sublist(0, 5);
    }

    return cards;
  }

  Future<void> unloadModel() async {
    await _gemmaService.unloadModel();
  }
}
