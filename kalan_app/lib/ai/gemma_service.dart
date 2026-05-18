import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/core/model.dart';

class GemmaService {
  final FlutterGemmaPlugin _plugin = FlutterGemmaPlugin.instance;
  InferenceModel? _model;
  InferenceModelSession? _session;

  Future<bool> isModelInstalled() => _plugin.modelManager.isModelInstalled;

  Future<void> loadModel({int maxTokens = 2048}) async {
    if (_model != null) return;
    try {
      _model = await _plugin.createModel(modelType: ModelType.gemmaIt, maxTokens: maxTokens);
      _session = await _model!.createSession(temperature: 0.7, topK: 1);
    } catch (e) {
      debugPrint('Error loading Gemma model: $e');
      rethrow;
    }
  }

  Future<String> generateText(String prompt, {int maxTokens = 512}) async {
    if (_model == null || _session == null) {
      await loadModel(maxTokens: maxTokens);
    }

    try {
      await _session!.addQueryChunk(Message.text(text: prompt, isUser: true));
      final result = await _session!.getResponse();
      return result;
    } catch (e) {
      debugPrint('Error generating text with Gemma: $e');
      rethrow;
    }
  }

  Future<void> unloadModel() async {
    try {
      await _session?.close();
      _session = null;
      await _model?.close();
      _model = null;
    } catch (e) {
      debugPrint('Error unloading Gemma model: $e');
    }
  }
}
