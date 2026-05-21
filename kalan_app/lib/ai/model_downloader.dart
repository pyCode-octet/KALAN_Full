import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/foundation.dart';

class ModelDownloader {
  // URL du modèle Gemma 3 1B (environ 600-800 Mo)
  static const String modelUrl = 'https://github.com/Blackdry13579/Gemma3-1B/releases/download/V1.0/gemma3-1b-it-int4.task';

  /// Vérifie si le modèle est déjà installé via le plugin
  static Future<bool> isModelDownloaded() async {
    return await FlutterGemmaPlugin.instance.modelManager.isModelInstalled;
  }

  /// Télécharge le modèle avec progression (0.0 - 1.0)
  static Stream<double> downloadModel() async* {
    try {
      debugPrint('[ModelDownloader] Vérification du modèle...');
      final isInstalled = await isModelDownloaded();
      if (isInstalled) {
        debugPrint('[ModelDownloader] Modèle déjà installé !');
        yield 1.0;
        return;
      }
      
      debugPrint('[ModelDownloader] Démarrage du téléchargement du modèle Gemma...');
      debugPrint('[ModelDownloader] Connexion sécurisée au dépôt gated...');
      
      late final Stream<int> rawStream;
      try {
        rawStream = FlutterGemmaPlugin.instance.modelManager.downloadModelFromNetworkWithProgress(modelUrl);
      } catch (e) {
        debugPrint('[ModelDownloader] Erreur d\'initialisation du téléchargement : $e');
        yield -1.0;
        return;
      }

      // Gestion sécurisée des erreurs de flux pour éviter les exceptions non gérées
      final secureStream = rawStream.handleError((error) {
        debugPrint('[ModelDownloader] Erreur reçue du flux natif : $error');
      });
      
      await for (final percent in secureStream) {
        final progress = (percent.clamp(0, 100) / 100.0);
        debugPrint('[ModelDownloader] Progression : ${(progress * 100).toInt()}%');
        yield progress;
      }
      
      debugPrint('[ModelDownloader] Téléchargement terminé avec succès !');
      yield 1.0;
    } catch (e) {
      debugPrint('[ModelDownloader] Exception lors du téléchargement : $e');
      yield -1.0;
    }
  }
}
