import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoyaku_mate_provider/constants/api_config.dart';

/// 端末セッションの発行・保持・破棄を担当する
/// - サーバーは1ユーザーにつき1端末のみ有効なセッションを保持する。新しい端末でログインすると
///   それ以前の端末のセッションは無効化され、そちらは次のリクエストで弾かれる
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const _sessionIdKey = 'session_id';
  static const _deviceIdKey = 'device_id';

  /// - リクエストのたびにSharedPreferencesを読むのを避けるためのメモリキャッシュ
  String? _cachedSessionId;

  /// - 同時に複数のリクエストが401(SESSION_REQUIRED)を受け取った場合に、
  ///   セッション発行が並行して走らないようにするためのガード
  Future<String?>? _inFlightEstablish;

  /// セッションが無効化された(他端末でログインされた)ことを通知するストリーム
  /// - 画面ごとに401を処理すると必ず抜け漏れが出るため、アプリのルートで1箇所だけ購読する
  final StreamController<void> _revokedController =
      StreamController<void>.broadcast();
  Stream<void> get onRevoked => _revokedController.stream;

  /// 現在のセッションIDを返す (未確立ならnull)
  Future<String?> getSessionId() async {
    if (_cachedSessionId != null) return _cachedSessionId;
    final prefs = await SharedPreferences.getInstance();
    _cachedSessionId = prefs.getString(_sessionIdKey);
    return _cachedSessionId;
  }

  /// 端末識別子を返す。無ければ生成して保存する
  /// - アプリを再インストールすると新しい値になるが、それは「別の端末とみなす」という意図通りの挙動
  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final random = Random.secure();
    final deviceId = List<int>.generate(16, (_) => random.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  /// 表示用の端末名 (将来の「ログイン中の端末一覧」で使う想定)
  String _deviceName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return '';
    }
  }

  String _platform() {
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }

  /// ローカルにセッションが無い場合のみ発行する
  /// - アプリ起動時に呼ぶ。Firebaseのセッションは残っているがローカルの端末セッションが
  ///   失われている状態(再インストール直後など)を、ユーザーに見せずに解消するため
  /// - 特にファイルアップロードは本文を再生できずリトライできないので、
  ///   最初のリクエストを待たずにここで確立しておく
  Future<void> ensureEstablished() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    final existing = await getSessionId();
    if (existing != null) return;
    await establish();
  }

  /// セッションを発行する (ログイン直後、およびセッション未確立が判明した時に呼ぶ)
  /// - 同一端末に有効なセッションが残っている場合、サーバー側はそれを再利用するため、
  ///   この呼び出しが自分自身を無効化してしまうことはない
  /// - 並行呼び出しは1本にまとめる
  Future<String?> establish() {
    final inFlight = _inFlightEstablish;
    if (inFlight != null) return inFlight;

    final future = _establish().whenComplete(() {
      _inFlightEstablish = null;
    });
    _inFlightEstablish = future;
    return future;
  }

  Future<String?> _establish() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final idToken = await user.getIdToken();
    if (idToken == null) return null;

    final deviceId = await _getOrCreateDeviceId();

    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/api/auth/session'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'device_id': deviceId,
        'device_name': _deviceName(),
        'platform': _platform(),
      }),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    final data = decoded is Map && decoded['data'] is Map ? decoded['data'] : null;
    final sessionId = data == null ? null : data['session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionIdKey, sessionId);
    _cachedSessionId = sessionId;
    return sessionId;
  }

  /// ログアウト時にサーバー側のセッションを破棄し、ローカルの保存も消す
  /// - 破棄しないと、ログアウト済みの端末のセッションが有効なまま残り続ける
  Future<void> clear() async {
    final sessionId = await getSessionId();
    if (sessionId != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final idToken = await user?.getIdToken();
        if (idToken != null) {
          await http.delete(
            Uri.parse('${ApiConfig.apiUrl}/api/auth/session'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'X-Session-Id': sessionId,
            },
          );
        }
      } catch (_) {
        // - サーバーへの通知に失敗してもローカルのログアウトは進める。
        //   残ったセッションはTTLで自然に消える
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionIdKey);
    _cachedSessionId = null;
  }

  /// セッションが無効化されたことをアプリ全体に通知する (ApiClientから呼ばれる)
  void notifyRevoked() {
    _cachedSessionId = null;
    _revokedController.add(null);
  }
}
