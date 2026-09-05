import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yoyaku_mate_provider/services/session_service.dart';

/// サーバーが返すセッション関連のエラーコード (server: handlers/middleware.go と対応)
const String kErrCodeSessionRequired = 'SESSION_REQUIRED';
const String kErrCodeSessionRevoked = 'SESSION_REVOKED';

/// セッションヘッダの付与と401処理を一手に引き受けるHTTPクライアント
/// - 認証まわりを各画面・各サービスが個別に処理すると、必ず抜け漏れが発生する。
///   ここ1箇所に集約し、呼び出し側は通常のhttpクライアントと同じ感覚で使えるようにする
class ApiClient extends http.BaseClient {
  ApiClient._(this._inner);

  static final ApiClient instance = ApiClient._(http.Client());

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final sessionId = await SessionService.instance.getSessionId();
    if (sessionId != null && !request.headers.containsKey('X-Session-Id')) {
      request.headers['X-Session-Id'] = sessionId;
    }

    final response = await _inner.send(request);

    // - 401以外はそのまま返す (ボディを読み取らないことでストリーミング応答を壊さない)
    if (response.statusCode != 401) return response;

    final bodyBytes = await response.stream.toBytes();
    final code = _extractErrorCode(bodyBytes);

    // - セッション未確立: 再インストール等でローカルのトークンが失われた場合。
    //   静かに再発行して1度だけリトライする (ユーザーには何も見せない)
    if (code == kErrCodeSessionRequired && _canRetry(request)) {
      final newSessionId = await SessionService.instance.establish();
      if (newSessionId != null) {
        final retryRequest = _copyRequest(request);
        retryRequest.headers['X-Session-Id'] = newSessionId;
        return _inner.send(retryRequest);
      }
    }

    // - セッション無効化: 他端末でログインされた。アプリのルートに通知してログアウトさせる
    if (code == kErrCodeSessionRevoked) {
      SessionService.instance.notifyRevoked();
    }

    // - 読み取り済みのボディで応答を組み直して返す
    return http.StreamedResponse(
      Stream.value(bodyBytes),
      response.statusCode,
      contentLength: bodyBytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  /// レスポンスボディから機械可読なエラーコードを取り出す
  String? _extractErrorCode(List<int> bodyBytes) {
    try {
      final decoded = json.decode(utf8.decode(bodyBytes));
      if (decoded is Map && decoded['code'] is String) {
        return decoded['code'] as String;
      }
    } catch (_) {
      // - JSON以外のエラー応答 (プレーンテキスト等) はコード無しとして扱う
    }
    return null;
  }

  /// リトライ可能なリクエストか
  /// - ストリーム送信 (ファイルアップロード等) は本文を再生できないためリトライしない。
  ///   その場合は呼び出し側にエラーが返り、次の操作で再発行が走る
  bool _canRetry(http.BaseRequest request) => request is http.Request;

  http.Request _copyRequest(http.BaseRequest request) {
    final original = request as http.Request;
    return http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..bodyBytes = original.bodyBytes
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
  }
}

/// 各サービスから使う共有インスタンス
final ApiClient apiClient = ApiClient.instance;
