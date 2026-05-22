import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelDownloader {
  // URL du modèle Gemma 3 1B (environ 600-800 Mo)
  static const String modelUrl = 'https://github.com/Blackdry13579/Gemma3-1B/releases/download/V1.0/gemma3-1b-it-int4.task';

  /// Détecte et importe automatiquement le modèle si copié manuellement en stockage externe
  static Future<bool> importModelFromExternalStorage() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final targetFile = File('${docsDir.path}/gemma3-1b-it-int4.task');
      final prefs = await SharedPreferences.getInstance();

      // Cas 1 : Le modèle est déjà présent dans le stockage interne
      if (await targetFile.exists()) {
        final currentPref = prefs.getString('installed_model_file_name');
        if (currentPref != 'gemma3-1b-it-int4.task') {
          await prefs.setString('installed_model_file_name', 'gemma3-1b-it-int4.task');
          debugPrint('[ModelDownloader] Sync de la clé SharedPreferences effectuée.');
        }
        return true;
      }

      // Cas 2 : Le modèle est dans le stockage externe Android/data/com.kalan.kalan.kalan_app/files/
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final sourceFile = File('${extDir.path}/gemma3-1b-it-int4.task');
        if (await sourceFile.exists()) {
          debugPrint('[ModelDownloader] Modèle manuel détecté en externe à : ${sourceFile.path}');
          debugPrint('[ModelDownloader] Copie locale en cours vers le stockage interne privé...');
          
          // Copie locale rapide
          await sourceFile.copy(targetFile.path);
          
          // Enregistrement de la configuration attendue par flutter_gemma
          await prefs.setString('installed_model_file_name', 'gemma3-1b-it-int4.task');
          
          debugPrint('[ModelDownloader] ✅ Importation réussie. Le modèle Gemma 3 est actif !');
          return true;
        }
      }
    } catch (e) {
      debugPrint('[ModelDownloader] Erreur lors de l\'importation locale du modèle : $e');
    }
    return false;
  }

  /// Vérifie si le modèle est déjà installé (et tente l'importation au préalable)
  static Future<bool> isModelDownloaded() async {
    // 1. Tenter d'importer le modèle depuis le stockage externe s'il y est présent
    final imported = await importModelFromExternalStorage();
    if (imported) {
      return true;
    }
    
    // 2. Sinon, laisser le plugin faire sa vérification standard
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
