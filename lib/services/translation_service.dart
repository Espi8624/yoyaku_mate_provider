import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:yoyaku_mate_provider/services/api_client.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';

// 自動翻訳 (メニュー名/カテゴリー名/待機メモ) は Gemini API をサーバー経由で呼び出す。
// APIキーはクライアントに一切持たせず、yoyaku_mate_server の
// /api/provider_translate, /api/provider_translate/multi にプロキシさせる。
class TranslationService {
  // 常時翻訳対象とする基本言語。メニュー入力者(店舗スタッフ)が必ずしも
  // 日本語話者とは限らない(外国人スタッフが英語や韓国語で入力するケースがある)ため、
  // 「入力言語=日本語」を前提にせず、日本語・英語・韓国語の3言語は常に
  // 翻訳結果を持つようにする(入力言語がこの3言語のいずれかであっても、
  // Geminiにとってはただの自己翻訳になるだけで害はない)
  static const List<String> defaultLanguages = ['ja', 'en', 'ko'];

  // 店舗が「設定 > 店舗」の多言語対応設定で選択制に有効化できる追加言語
  static const List<String> optionalLanguages = [
    'zh', // Chinese (Simplified)
    'zh-TW', // Traditional Chinese
    'es', // Spanish
    'fr', // French
    'de', // German
    'it', // Italian
    'ar', // Arabic
    'ru', // Russian
  ];

  // 既存翻訳データの正規化・保持判定に使う、認識対象言語コードの全体集合。
  // 店舗が言語を無効化しても既存データはここでは失われず、有効/無効の絞り込みは
  // 呼び出し側がstoreSettings.supportedLanguagesを使って別途行う
  static const List<String> allLanguages = [
    ...defaultLanguages,
    ...optionalLanguages,
  ];

  // 後方互換: 以前の全言語固定リストを参照していた呼び出し元向けのエイリアス
  static const List<String> targetLanguages = allLanguages;

  // 多言語設定ダイアログ等で使う表示名(日本語UI向け)
  static const Map<String, String> languageLabels = {
    'ja': '日本語',
    'en': '英語',
    'ko': '韓国語',
    'zh': '中国語(簡体字)',
    'zh-TW': '中国語(繁体字)',
    'es': 'スペイン語',
    'fr': 'フランス語',
    'de': 'ドイツ語',
    'it': 'イタリア語',
    'ar': 'アラビア語',
    'ru': 'ロシア語',
  };

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
      final response = await apiClient.post(
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

      // - サーバーの共通ヘルパー(utils.RespondWithJSON)は本体を data でラップするため、
      //   他サービスと同じく data を剥がしてから読む
      final body = json.decode(utf8.decode(response.bodyBytes));
      final jsonResponse = body['data'] ?? body;
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

  // HTTPエラー時のユーザー向けメッセージ。サーバーの message があればそれを優先する
  String _describeHttpFailure(int statusCode, List<int> bodyBytes) {
    try {
      final body = json.decode(utf8.decode(bodyBytes));
      final message = body is Map ? body['message'] : null;
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {
      // JSON以外のレスポンス(プロキシのHTMLエラーページ等)は無視して定型文にフォールバック
    }
    return '翻訳に失敗しました (HTTP $statusCode)';
  }

  Future<Map<String, Map<String, String>>> translateToMultipleLanguages(
      Map<String, String> texts, List<String> targetLanguages,
      {bool smartMenuMode = false}) async {
    if (texts.isEmpty || targetLanguages.isEmpty) return {};

    try {
      final token = await _getIdToken();
      final response = await apiClient.post(
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

      // - 以前はここで空マップを返していたため、呼び出し元(特に一括バックフィル)が
      //   「翻訳0件の成功」として扱い、何も翻訳されていないのに完了扱いになっていた。
      //   失敗は必ず例外として呼び出し元に伝える
      if (response.statusCode != 200) {
        debugPrint(
            'Multi-Translation Error: ${response.statusCode} ${response.body}');
        throw TranslationException(
            _describeHttpFailure(response.statusCode, response.bodyBytes),
            statusCode: response.statusCode);
      }

      // - サーバーの共通ヘルパー(utils.RespondWithJSON)は本体を data でラップするため、
      //   他サービスと同じく data を剥がしてから読む
      final body = json.decode(utf8.decode(response.bodyBytes));
      final jsonResponse = body['data'] ?? body;
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
