import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:yoyaku_mate_provider/constants/api_keys.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();

  factory TranslationService() {
    return _instance;
  }

  TranslationService._internal();

  GenerativeModel? _model;

  void _initModel() {
    if (_model == null) {
      if (ApiKeys.geminiApiKey.isEmpty ||
          ApiKeys.geminiApiKey == 'YOUR_API_KEY_HERE') {
        throw Exception('API Key is not set.');
      }
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiKeys.geminiApiKey,
      );
    }
  }

  Future<String> translate(String text,
      {String targetLang = 'Japanese'}) async {
    try {
      _initModel();
    } catch (e) {
      return "Error: API Key not set.";
    }

    if (_model == null) return "Error: Model initialization failed.";

    final prompt =
        'Translate the following text to $targetLang naturally. Only return the translated text, no explanations:\n\n$text';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text ?? "Translation failed.";
    } catch (e) {
      return "Translation Error: $e";
    }
  }

  Stream<String> translateStream(String text,
      {String targetLang = 'Japanese'}) async* {
    try {
      _initModel();
    } catch (e) {
      yield "Error: API Key not set.";
      return;
    }

    if (_model == null) {
      yield "Error: Model initialization failed.";
      return;
    }

    final prompt =
        'Translate the following text to $targetLang naturally. Only return the translated text, no explanations:\n\n$text';

    try {
      final content = [Content.text(prompt)];
      final response = _model!.generateContentStream(content);
      await for (final chunk in response) {
        if (chunk.text != null) {
          yield chunk.text!;
        }
      }
    } catch (e) {
      yield "Translation Error: $e";
    }
  }
}
