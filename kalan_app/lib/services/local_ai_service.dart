import '../ai/gemma_service.dart';

class LocalAIService {
  final GemmaService _gemmaService = GemmaService();

  Future<List<Map<String, String>>> generateFlashcards({
    required String text,
    String subject = 'Général',
    String level = 'Scolaire',
  }) async {
    try {
      if (text.trim().length < 10) {
        return _fallbackFlashcards(text);
      }

      return await _gemmaService.generateFlashcards(
        text: text,
        subject: subject,
        level: level,
      );
    } catch (e) {
      print('LocalAIService error: $e');
      return _fallbackFlashcards(text);
    }
  }

  List<Map<String, String>> _fallbackFlashcards(String text) {
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.trim().length > 10).toList();
    
    if (sentences.isEmpty) {
      return [
        {'question': 'De quoi parle ce texte ?', 'answer': text.length > 50 ? text.substring(0, 50) + '...' : text}
      ];
    }

    return sentences.take(5).map((s) {
      final parts = s.trim().split(' ');
      if (parts.length > 4) {
        final half = (parts.length / 2).floor();
        return {
          'question': parts.sublist(0, half).join(' ') + ' ?',
          'answer': parts.sublist(half).join(' '),
        };
      }
      return {
        'question': 'Explique ceci :',
        'answer': s.trim(),
      };
    }).toList();
  }
}
