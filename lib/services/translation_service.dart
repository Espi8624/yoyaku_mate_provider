import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
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
        httpClient: _CustomHttpClient(),
      );
    }
  }

  Future<String> translate(String text,
      {String targetLang = 'Japanese'}) async {
    try {
      _initModel();
    } catch (e) {
      debugPrint('Translation Init Error: $e');
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
      debugPrint('Translation Error (Single): $e');
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
      debugPrint('Translation Error (Stream): $e');
      yield "Translation Error: $e";
    }
  }

  Future<Map<String, String>> translateBatch(Map<String, String> texts,
      {String targetLang = 'Japanese',
      bool includeRomaji = false,
      bool smartMenuMode = false}) async {
    try {
      _initModel();
    } catch (e) {
      debugPrint('Translation Batch Init Error: $e');
      return {};
    }

    if (_model == null || texts.isEmpty) return {};

    final promptLines =
        texts.entries.map((e) => '${e.key}: ${e.value}').join('\n');

    String instruction =
        'Translate the following lines to $targetLang naturally. Each line is in the format "id: text". Translate only the "text" part. Return the line in the "id: translated_text" format. Do NOT change the "id" part.';

    if (smartMenuMode) {
      instruction += '''
 Rules for Romaji:
 1. If the Key starts with "t_" (e.g. t_0, t_1), you MUST append the Japanese pronunciation in Romaji separated by " / ". Format: "Translated / Romaji". Example: "Chicken / toriniku". EVEN IF the pronunciation sounds the same (e.g. Ramen / ramen), you MUST append it.
 2. If the Key starts with "d_" (e.g. d_0, d_1), do NOT append Romaji. Just return the translated text.
''';
    } else if (includeRomaji) {
      instruction +=
          ' Also, append the Japanese pronunciation in Romaji (Roman alphabet) separated by a slash " / ". Format: "Translated Text / Romaji". Example: "Chicken / toriniku".';
    }

    final prompt = '''
$instruction

$promptLines
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        debugPrint('Translation Batch Error: Empty response text');
        return {};
      }

      final result = <String, String>{};
      final lines = responseText.split('\n');
      for (final line in lines) {
        final parts = line.split(': ');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(': ').trim();
          result[key] = value;
        }
      }
      return result;
    } catch (e) {
      debugPrint('Translation Batch Error: $e');
      rethrow;
    }
  }

  static String normalizeLanguageCode(String code) {
    final lowerCode = code.toLowerCase();
    if (lowerCode.contains('english') ||
        lowerCode == 'en-us' ||
        lowerCode == 'en') {
      return 'en';
    } else if (lowerCode.contains('korean') || lowerCode == 'ko') {
      return 'ko';
    } else if (lowerCode.contains('traditional chinese') ||
        lowerCode.contains('hant') ||
        lowerCode == 'zh-tw') {
      return 'zh-TW';
    } else if (lowerCode.contains('chinese') ||
        lowerCode.contains('hans') ||
        lowerCode == 'zh-cn' ||
        lowerCode == 'zh') {
      return 'zh';
    } else if (lowerCode.contains('japanese') || lowerCode == 'ja') {
      return 'ja';
    } else if (lowerCode.contains('spanish') || lowerCode == 'es') {
      return 'es';
    } else if (lowerCode.contains('french') || lowerCode == 'fr') {
      return 'fr';
    } else if (lowerCode.contains('german') || lowerCode == 'de') {
      return 'de';
    } else if (lowerCode.contains('italian') || lowerCode == 'it') {
      return 'it';
    } else if (lowerCode.contains('arabic') || lowerCode == 'ar') {
      return 'ar';
    } else if (lowerCode.contains('russian') || lowerCode == 'ru') {
      return 'ru';
    } else if (lowerCode.contains('portuguese') || lowerCode == 'pt') {
      return 'pt';
    } else if (lowerCode.contains('thai') || lowerCode == 'th') {
      return 'th';
    } else if (lowerCode.contains('vietnamese') || lowerCode == 'vi') {
      return 'vi';
    } else if (lowerCode.contains('indonesian') || lowerCode == 'id') {
      return 'id';
    }
    return code;
  }

  Future<Map<String, Map<String, String>>> translateToMultipleLanguages(
      Map<String, String> texts, List<String> targetLanguages,
      {bool smartMenuMode = false}) async {
    try {
      _initModel();
    } catch (e) {
      debugPrint('Multi-Translation Init Error: $e');
      return {};
    }

    if (_model == null || texts.isEmpty || targetLanguages.isEmpty) return {};

    // Map ISO codes to descriptive names for better translation quality
    final languageNames = {
      'en': 'English',
      'ko': 'Korean',
      'zh': 'Chinese (Simplified)',
      'zh-TW': 'Traditional Chinese (Taiwan)',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'ar': 'Arabic',
      'ru': 'Russian',
      'pt': 'Portuguese',
      'th': 'Thai',
      'vi': 'Vietnamese',
      'id': 'Indonesian',
    };

    // Use full names for the prompt instructions
    final promptLanguages =
        targetLanguages.map((code) => languageNames[code] ?? code).join(', ');

    final promptLines =
        texts.entries.map((e) => '${e.key}: ${e.value}').join('\n');

    String instruction = '''
You are a professional menu translator. Translate the following lines into the following languages: $promptLanguages.
The input lines are in "id: text" format.
Return a SINGLE JSON object where:
- Keys are the EXACT Language Codes provided: $targetLanguages.
- For Chinese, use "zh" for Simplified and "zh-TW" for Traditional Chinese.
- Values are objects mapping "id" to "translated_text".
Rules:
1. Translate naturally and accurately for a restaurant menu.
''';

    if (smartMenuMode) {
      instruction += '''
2. If the input Key starts with "t_" (Title), you MUST append the Japanese pronunciation in Romaji separated by " / ". 
   Format: "Translated Text / Romaji". Example: "Fried Chicken / Karaage".
3. If the input Key starts with "d_" (Description), do NOT append Romaji.
''';
    }

    instruction += '''
4. Return ONLY the JSON object. No markdown formatting, no code blocks, no intro text.
''';

    final prompt = '''
$instruction

Input Data:
$promptLines
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text;

      if (responseText == null) {
        debugPrint('Multi-Translation Error: Empty response');
        return {};
      }

      // Cleanup JSON string if it contains markdown code blocks
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      }
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }

      final deepMap = jsonDecode(cleanJson) as Map<String, dynamic>;
      final result = <String, Map<String, String>>{};

      deepMap.forEach((lang, transMap) {
        if (transMap is Map) {
          final normalizedKey = normalizeLanguageCode(lang);

          // Only keep if it's one of the requested languages (or was mapped to one)
          if (targetLanguages.contains(normalizedKey)) {
            result[normalizedKey] = Map<String, String>.from(
                transMap.map((k, v) => MapEntry(k.toString(), v.toString())));
          }
        }
      });
      return result;
    } catch (e) {
      debugPrint('Multi-Translation Error: $e');
      rethrow;
    }
  }
}

class _CustomHttpClient extends http.BaseClient {
  final _client = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add Referer header
    // Replace with the domain allowed in Google Cloud Console
    request.headers['Referer'] = 'https://yoyaku-mate.vercel.app';
    // request.headers['X-Goog-Api-Key'] = ApiKeys.geminiApiKey; // SDK usually handles this

    return _client.send(request);
  }
}
