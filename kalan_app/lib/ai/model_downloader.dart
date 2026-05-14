import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ModelDownloader {
  static const String modelUrl = 'https://huggingface.co/google/gemma-2b-it/resolve/main/gemma-2b-it-q4_k_m.gguf';
  static const String modelFileName = 'gemma-2b-it-q4_k_m.gguf';
  
  /// Vérifie si le modèle est déjà téléchargé
  static Future<bool> isModelDownloaded() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/$modelFileName');
    return file.existsSync();
  }
  
  /// Télécharge le modèle avec progression
  static Stream<double> downloadModel() async* {
    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!modelDir.existsSync()) modelDir.createSync(recursive: true);
    
    final file = File('${modelDir.path}/$modelFileName');
    
    final request = http.Request('GET', Uri.parse(modelUrl));
    final response = await http.Client().send(request);
    
    final total = response.contentLength ?? 0;
    var received = 0;
    
    final sink = file.openWrite();
    
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) {
        yield received / total;
      } else {
        yield 0.0;
      }
    }
    
    await sink.close();
    yield 1.0;
  }
}
