import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // バックエンドサーバーのAPI URLを取得する。環境変数がない場合はプラットフォームに応じたローカルの既定値にフォールバックする。
  static String get apiUrl {
    var value = dotenv.env['API_URL'];
    if (value != null && value.isNotEmpty) {
      // 既存のサービスコードが全て '$baseUrl/api/...' と結合する設計になっているため、
      // API_URL の末尾に '/api' が含まれている場合は重複防止のために除去します。
      if (value.endsWith('/api')) {
        value = value.substring(0, value.length - 4);
      }
      return value;
    }
    // AndroidのエミュレータとiOSシミュレータ/Web環境のフォールバック
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  // クライアントウェブのベースURLを取得する。環境変数がない場合はローカルの既定値にフォールバックする。
  static String get webBaseUrl {
    final value = dotenv.env['WEB_BASE_URL'];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'http://localhost:3000';
  }
}
