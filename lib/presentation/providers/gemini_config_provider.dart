import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GeminiConfig {
  final String apiKey;
  final String modelName;

  const GeminiConfig({
    required this.apiKey,
    this.modelName = 'gemini-2.5-flash',
  });

  bool get isValid => apiKey.trim().isNotEmpty;
}

class GeminiConfigNotifier extends Notifier<GeminiConfig> {
  static const String _boxName = 'app_settings';
  static const String _keyApi = 'gemini_api_key';
  static const String _keyModel = 'gemini_model';

  @override
  GeminiConfig build() {
    Future.microtask(_load);
    return const GeminiConfig(apiKey: '', modelName: 'gemini-2.5-flash');
  }

  Future<void> _load() async {
    final box = await Hive.openBox(_boxName);
    final key = box.get(_keyApi, defaultValue: '') as String;
    var model = box.get(_keyModel, defaultValue: 'gemini-2.5-flash') as String;
    if (model.contains('3.8') || model.trim().isEmpty) {
      model = 'gemini-2.5-flash';
      await box.put(_keyModel, model);
    }
    state = GeminiConfig(apiKey: key, modelName: model);
  }

  Future<void> updateConfig({required String apiKey, String? modelName}) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_keyApi, apiKey);
    var chosenModel = modelName?.trim() ?? '';
    if (chosenModel.isEmpty || chosenModel.contains('3.8')) {
      chosenModel = 'gemini-2.5-flash';
    }
    await box.put(_keyModel, chosenModel);
    state = GeminiConfig(
      apiKey: apiKey,
      modelName: chosenModel,
    );
  }
}

final geminiConfigProvider =
    NotifierProvider<GeminiConfigNotifier, GeminiConfig>(GeminiConfigNotifier.new);
