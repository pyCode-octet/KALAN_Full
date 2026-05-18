import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Extrait le texte d'un fichier PDF, limité aux [maxPages] premières pages, en utilisant un isolate.
  Future<String> extractText({String? filePath, List<int>? bytes, int maxPages = 10}) async {
    try {
      final result = await compute(_extractTextTask, {
        'filePath': filePath,
        'bytes': bytes,
        'maxPages': maxPages,
      });
      return result;
    } catch (e) {
      debugPrint('[PdfService] Erreur lors de l\'extraction PDF : $e');
      throw Exception('Erreur lors de la lecture du PDF : $e');
    }
  }
}

/// Fonction de niveau supérieur exécutée dans un Isolate séparé.
Future<String> _extractTextTask(Map<String, dynamic> args) async {
  final filePath = args['filePath'] as String?;
  final bytes = args['bytes'] as List<int>?;
  final maxPages = args['maxPages'] as int;

  final List<int> pdfBytes;
  if (bytes != null) {
    debugPrint('[PdfService Isolate] Extraction à partir de bytes (${bytes.length} octets)');
    pdfBytes = bytes;
  } else if (filePath != null) {
    debugPrint('[PdfService Isolate] Extraction à partir du fichier : $filePath');
    final File file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Le fichier PDF n\'existe pas à l\'emplacement : $filePath');
    }
    pdfBytes = await file.readAsBytes();
    debugPrint('[PdfService Isolate] Fichier lu avec succès (${pdfBytes.length} octets)');
  } else {
    throw Exception('Aucune source de fichier PDF fournie (chemin ou octets nuls).');
  }
  
  // Chargement du document PDF
  final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
  final int totalPages = document.pages.count;
  debugPrint('[PdfService Isolate] Document PDF chargé. Nombre total de pages : $totalPages');
  
  if (totalPages == 0) {
    document.dispose();
    return '';
  }

  // Détermination du nombre de pages à traiter
  int pagesToProcess = totalPages;
  if (pagesToProcess > maxPages) {
    pagesToProcess = maxPages;
    debugPrint('[PdfService Isolate] Limitation de l\'extraction aux $maxPages premières pages.');
  }

  // Extraction globale par plage (recommandé par Syncfusion pour la stabilité)
  final PdfTextExtractor extractor = PdfTextExtractor(document);
  final String extractedText = extractor.extractText(
    startPageIndex: 0,
    endPageIndex: pagesToProcess - 1,
  );

  document.dispose();
  
  final String trimmedText = extractedText.trim();
  debugPrint('[PdfService Isolate] Extraction terminée ! Longueur : ${trimmedText.length} caractères');
  
  return trimmedText;
}
