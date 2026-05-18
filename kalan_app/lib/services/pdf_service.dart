import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// Extrait le texte d'un fichier PDF, limité aux [maxPages] premières pages.
  Future<String> extractText(String filePath, {int maxPages = 10}) async {
    try {
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();
      
      // Chargement du document PDF
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Détermination du nombre de pages à traiter
      int pagesToProcess = document.pages.count;
      if (pagesToProcess > maxPages) {
        pagesToProcess = maxPages;
      }

      String fullText = '';
      
      // Extraction page par page
      for (int i = 0; i < pagesToProcess; i++) {
        fullText += PdfTextExtractor(document).extractText(startPageIndex: i, endPageIndex: i);
        fullText += '\n'; // Séparateur de page
      }

      document.dispose();
      return fullText.trim();
    } catch (e) {
      throw Exception('Erreur lors de la lecture du PDF : $e');
    }
  }
}
