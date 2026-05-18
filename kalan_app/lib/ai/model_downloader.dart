import 'package:flutter_gemma/flutter_gemma.dart';

class ModelDownloader {
  static const String modelUrl = 'https://huggingface.co/litert-community/gemma-3-270m-it/resolve/main/gemma-3-270m-it.task';

  /// Vérifie si le modèle est déjà installé via le plugin
  static Future<bool> isModelDownloaded() async {
    return await FlutterGemmaPlugin.instance.modelManager.isModelInstalled;
  }

  /// Télécharge le modèle avec progression (0.0 - 1.0)
  static Stream<double> downloadModel() async* {
    final progStream = FlutterGemmaPlugin.instance.modelManager.downloadModelFromNetworkWithProgress(modelUrl);
    await for (final percent in progStream) {
      yield (percent.clamp(0, 100) / 100.0);
    }
    yield 1.0;
  }
}
