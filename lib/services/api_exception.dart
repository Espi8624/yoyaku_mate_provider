// API通信時発生する例外を定義する

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    return 'ApiException: $message (Status Code: $statusCode)';
  }
}

// 自動翻訳(Gemini プロキシ)の失敗を表す専用例外。
// 呼び出し側が「翻訳だけ失敗した」ことを他のAPI失敗と区別できるようにする。
class TranslationException extends ApiException {
  const TranslationException(super.message, {super.statusCode});
}

// ユーザープロフィールが未登録(サインアップ未完了)の場合に投げる専用例外。
// 呼び出し側はこれを「エラー」ではなく「サインアップへの誘導」として扱う。
class ProfileNotFoundException extends ApiException {
  const ProfileNotFoundException(super.message, {super.statusCode});
}
