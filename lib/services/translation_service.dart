import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// 自動翻訳 (メニュー名/カテゴリー名/待機メモ) は Gemini API をサーバー経由で呼び出す。
// APIキーはクライアントに一切持たせず、yoyaku_mate_server の
// /api/provider_translate, /api/provider_translate/multi にプロキシさせる。
class TranslationService {
  // メニュー/カテゴリー自動翻訳の対象言語 (共通)
  static const List<String> targetLanguages = [
    'en', // English
    'ko', // Korean
    'zh', // Chinese (Simplified)
    'zh-TW', // Traditional Chinese
    'es', // Spanish
    'fr', // French
    'de', // German
    'it', // Italian
    'ar', // Arabic
    'ru', // Russian
  ];

  static final TranslationService _instance = TranslationService._internal();

  factory TranslationService() {
    return _instance;
  }

  TranslationService._internal();

  String get _baseUrl => dotenv.env['API_URL']!;

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in.');
    final token = await user.getIdToken();
    if (token == null) throw Exception('Failed to get auth token.');
    return token;
  }

  Future<String> translate(String text,
      {String targetLang = 'Japanese'}) async {
    try {
      final token = await _getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/provider_translate'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'text': text, 'target_lang': targetLang}),
      );

      if (response.statusCode != 200) {
        debugPrint(
            'Translation Error: ${response.statusCode} ${response.body}');
        return "Translation failed.";
      }

      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      return jsonResponse['translated_text'] ?? "Translation failed.";
    } catch (e) {
      debugPrint('Translation Error (Single): $e');
      return "Translation Error: $e";
    }
  }

  // サーバー側は現状ストリーミング非対応のため、結果が揃い次第1回だけyieldする
  // (呼び出し元は既存の利用箇所なし。将来の利用に備えてシグネチャのみ維持)
  Stream<String> translateStream(String text,
      {String targetLang = 'Japanese'}) async* {
    yield await translate(text, targetLang: targetLang);
  }

  // targetLanguages(単一言語)をtranslateToMultipleLanguagesに委譲する薄いラッパー
  // (呼び出し元は既存の利用箇所なし。将来の利用に備えてシグネチャのみ維持)
  Future<Map<String, String>> translateBatch(Map<String, String> texts,
      {String targetLang = 'Japanese',
      bool includeRomaji = false,
      bool smartMenuMode = false}) async {
    if (texts.isEmpty) return {};
    final code = normalizeLanguageCode(targetLang);
    final result = await translateToMultipleLanguages(texts, [code],
        smartMenuMode: smartMenuMode || includeRomaji);
    return result[code] ?? {};
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
    if (texts.isEmpty || targetLanguages.isEmpty) return {};

    try {
      final token = await _getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/provider_translate/multi'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'texts': texts,
          'target_languages': targetLanguages,
          'smart_menu_mode': smartMenuMode,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
            'Multi-Translation Error: ${response.statusCode} ${response.body}');
        return {};
      }

      final jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      final deepMap =
          jsonResponse['translations'] as Map<String, dynamic>? ?? {};
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
