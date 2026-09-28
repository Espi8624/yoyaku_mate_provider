import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yoyaku_mate_provider/constants/api_config.dart';
import 'package:yoyaku_mate_provider/services/api_client.dart';
import 'package:yoyaku_mate_provider/services/session_service.dart';
import '../models/waiting_list.dart';

class WaitingService {
  static final WaitingService _instance = WaitingService._internal();
  late StreamController<List<WaitingList>> _waitingListController;
  bool _isConnected = false;
  // - 他サービスと同じくApiConfig経由に統一する。
  //   dotenvを直接"!"で参照すると、環境変数の設定漏れがそのままクラッシュになる
  static String get _baseUrl => ApiConfig.apiUrl;

  // SSE接続クライアント
  http.Client? _client;
  String? _lastStoreId;
  StreamSubscription<String>? _streamSubscription;

  // - 接続の世代番号。再接続のたびに加算し、古い接続から遅れて届く
  //   onDone/onError/awaitの完了を無視するために使う。
  //   これが無いと、張り直した直後に前の接続の切断通知が入って
  //   新しい接続を巻き添えで落としてしまう
  int _connectionGeneration = 0;

  // 再接続用変数
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0; // 指数バックオフカウンター

  // 接続監視(watchdog)用
  Timer? _watchdogTimer;
  DateTime? _lastReceivedAt;

  // - サーバーのheartbeatは30秒周期 (server: events/broker.go)。
  //   2回分を取りこぼしても誤検知しないよう45秒を無通信の上限とする
  static const Duration _staleThreshold = Duration(seconds: 45);
  static const Duration _watchdogInterval = Duration(seconds: 15);

  WaitingService._internal() {
    _waitingListController = StreamController<List<WaitingList>>.broadcast();
  }

  factory WaitingService() {
    return _instance;
  }

  Stream<List<WaitingList>> get waitingListStream =>
      _waitingListController.stream;
  bool get isConnected => _isConnected;

  // 初期データ取得 (以前と同じ)
  Future<List<WaitingList>> fetchWaitingCustomers(String storeId) async {
    try {
      final response = await apiClient.get(
        Uri.parse('$_baseUrl/api/waiting-list?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) {
            try {
              return WaitingList.fromJson(json);
            } catch (e) {
              rethrow;
            }
          }).toList();
        } else {
          return [];
        }
      }
      throw Exception(
          'Server returned ${response.statusCode}: ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  void startPolling(String storeId) {
    unawaited(connectToStream(storeId));
  }

  // SSEストリームへ接続する。
  // force=true の場合、「接続済み」とみなされている状態でも強制的に張り直す
  // (watchdogによる切断検知からの復帰で使う)
  Future<void> connectToStream(String storeId, {bool force = false}) async {
    if (!force && _isConnected && _lastStoreId == storeId) return;

    final generation = ++_connectionGeneration;

    await _closeCurrentConnection();
    // - 上のawait中に別の接続要求が入っていた場合、ここから先の共有状態
    //   (_client/_lastReceivedAt/watchdog)を上書きすると新しい接続を壊してしまう
    if (generation != _connectionGeneration) return;
    _reconnectTimer?.cancel();

    final client = http.Client();
    _client = client;
    _lastStoreId = storeId;
    _isConnected = true;
    // - 接続開始時刻を起点にしておかないと、初回応答が来る前にwatchdogが誤発火する
    _lastReceivedAt = DateTime.now();
    _startWatchdog(storeId, generation);

    final request = http.Request(
      'GET',
      Uri.parse('$_baseUrl/api/waiting-list/stream?store_id=$storeId'),
    );
    request.headers['Cache-Control'] = 'no-cache';
    request.headers['Accept'] = 'text/event-stream';

    // - SSEだけはapiClientを経由しない(接続の生存期間を自前で管理するため、
    //   共有クライアントをcloseできない)ので、セッションヘッダを自分で付与する。
    //   これが無いとサーバーが非スタッフ接続とみなし、contact(電話番号)を
    //   伏せたデータを配信してしまう (server: handlers/waiting_list_handler.go)
    final sessionId = await SessionService.instance.getSessionId();
    if (generation != _connectionGeneration) return; // await中に世代交代した
    if (sessionId != null) {
      request.headers['X-Session-Id'] = sessionId;
    }

    try {
      final response = await client.send(request);
      if (generation != _connectionGeneration) return;

      if (response.statusCode != 200) {
        _log('SSE接続失敗: ${response.statusCode}');
        _handleDisconnect(storeId, generation);
        return;
      }

      _streamSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) => _handleLine(line, generation),
        onError: (Object e) {
          _log('SSEストリームエラー: $e');
          _handleDisconnect(storeId, generation);
        },
        onDone: () {
          _log('SSEストリーム切断');
          _handleDisconnect(storeId, generation);
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (generation != _connectionGeneration) return;
      _log('SSE接続エラー: $e');
      _handleDisconnect(storeId, generation);
    }
  }

  void _handleLine(String line, int generation) {
    if (generation != _connectionGeneration) return;

    // - 受信した行は内容を問わず生存確認として扱う。heartbeatも空行も含めることで、
    //   サーバー側のheartbeat形式が変わっても切断検知が壊れない
    _lastReceivedAt = DateTime.now();
    _reconnectAttempts = 0;

    if (!line.startsWith('data: ')) return;
    final data = line.substring(6);

    // - サーバーのheartbeatは現状 "data: :ping" として届く (server: events/broker.go)。
    //   SSEコメント(":ping")へ直された場合はそもそもこの行に来ないので、
    //   どちらの形式でも無視される
    if (data.startsWith(':')) return;

    try {
      final decoded = json.decode(data);
      // - 想定外の形(Goのnilスライスによる"null"等)で既存の表示を壊さないよう、
      //   配列以外は捨てる
      if (decoded is! List) return;
      _waitingListController.add(
        decoded
            .map((item) => WaitingList.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      _log('SSEデータパースエラー: $e');
    }
  }

  // 一定時間まったく受信が無ければ、ソケットがhalf-openのまま死んでいるとみなして張り直す。
  // - この状態ではonDone/onErrorが発火しないため、_isConnectedがtrueのまま残り、
  //   画面を出入りしてもアプリを復帰させても二度と再接続されなくなる
  void _startWatchdog(String storeId, int generation) {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      if (generation != _connectionGeneration) return;
      final last = _lastReceivedAt;
      if (last == null) return;
      if (DateTime.now().difference(last) < _staleThreshold) return;

      _log('SSE無通信を検知 (${DateTime.now().difference(last).inSeconds}秒)、再接続します');
      _handleDisconnect(storeId, generation);
    });
  }

  void _handleDisconnect(String storeId, int generation) {
    // - 古い接続からの通知は無視する。あわせて世代を進めることで、
    //   同じ接続から二重に切断通知が来ても再接続は1回だけになる
    if (generation != _connectionGeneration) return;
    _connectionGeneration++;

    _isConnected = false;
    _watchdogTimer?.cancel();
    _reconnectTimer?.cancel();

    // 指数バックオフ: 3s -> 6s -> 10s (上限10秒)
    // - 以前は上限60秒かつ「200応答時のみカウンターリセット」だったため、
    //   サーバーの再起動などで一度切れると復帰に1分近くかかっていた
    final delaySeconds = (3 * (1 << _reconnectAttempts)).clamp(3, 10);
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      unawaited(connectToStream(storeId, force: true));
    });
  }

  Future<void> _closeCurrentConnection() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _client?.close();
    _client = null;
  }

  void stopPolling() {
    _connectionGeneration++; // 以降、進行中の接続からの通知を全て無視する
    _isConnected = false;
    _reconnectAttempts = 0; // 停止時カウンターリセット
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    unawaited(_closeCurrentConnection());
    _lastStoreId = null;
    _lastReceivedAt = null;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[WaitingService] $message');
  }

  void dispose() {
    stopPolling();
    _waitingListController.close();
  }

  // --- 以下、既存メソッド (機能変更なし) ---

  // Firebase ID トークン取得
  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get ID token');
    }
    return token;
  }

  // 新規待機追加 (冪等性サポートのためのクライアント生成IDおよび登録時間パラメータを追加)
  Future<WaitingList> createWaitingListItem({
    required int partySize,
    required String contact,
    required String nationality,
    String notes = '',
    required String storeId,
    String? vToken, // Added vToken parameter
    List<MenuItem>? menuItems,
    String? waitingId, // 冪等性検証用のクライアント生成待機ID
    String? registrationTime, // クライアント側で記録された実際の登録時刻
  }) async {
    try {
      // 冪等性の確保のため、クライアントで生成したWaitingIDを使用可能

      final Map<String, dynamic> requestBody = {
        'store_id': storeId,
        if (waitingId != null) 'waiting_id': waitingId,
        if (registrationTime != null) 'registration_time': registrationTime,
        'party_size': partySize,
        'nationality': nationality,
        'contact': contact,
        'notes': notes,
        'status': 'waiting',
        if (menuItems != null)
          'menu_items': menuItems.map((e) => e.toJson()).toList(),
      };

      final headers = <String, String>{'Content-Type': 'application/json'};
      try {
        final token = await _getIdToken();
        headers['Authorization'] = 'Bearer $token';
      } catch (e) {
        // print('未認証、Authヘッダーなしで続行');
      }

      // Add vToken to query parameters if present
      final uri = Uri.parse('$_baseUrl/api/waiting-list').replace(
          queryParameters: vToken != null ? {'v_token': vToken} : null);

      final response = await apiClient.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return WaitingList.fromJson(jsonResponse['data']);
      }
      throw Exception(response.body);
    } catch (e) {
      rethrow;
    }
  }

  // 待機状態更新
  Future<void> updateWaitingStatus({
    required String waitingId,
    required String status,
    required String storeId,
  }) async {
    try {
      final token = await _getIdToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await apiClient.patch(
        Uri.parse('$_baseUrl/api/waiting-list?action=status'),
        headers: headers,
        body: json.encode({
          'store_id': storeId,
          'waiting_id': waitingId,
          'status': status,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update status: ${response.statusCode}, Body: ${response.body}');
      }
      // ポーリング再開不要、SSEが更新を処理
    } catch (e) {
      rethrow;
    }
  }

  // 待機目録初期化
  Future<void> clearWaitingList(String storeId) async {
    try {
      final token = await _getIdToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await apiClient.post(
        Uri.parse('$_baseUrl/api/waiting-list?action=clear&store_id=$storeId'),
        headers: headers,
        body: '{}',
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to clear waiting list: ${response.statusCode}, Body: ${response.body}');
      }
      // ポーリング再開不要
    } catch (e) {
      rethrow;
    }
  }

  // QRトークン取得 (board_key検証必須。事前に fetchBoardKey で取得した値を渡すこと)
  Future<Map<String, String>> fetchQRToken(String storeId, String boardKey) async {
    try {
      final token = await _getIdToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await apiClient.get(
        Uri.parse(
            '$_baseUrl/api/waiting-list?action=qr_token&store_id=$storeId&board_key=$boardKey'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'] as Map<String, dynamic>;

        return {
          'v_token': data['v_token'] as String,
          'date': data['date'] as String,
        };
      }
      throw Exception('Failed to fetch QR token: ${response.body}');
    } catch (e) {
      rethrow;
    }
  }

  // 店舗別board_key取得 (未設定ならサーバー側で生成。モニターボードURL・QRトークン発行の両方に使う)
  Future<String> fetchBoardKey(String storeId) async {
    try {
      final token = await _getIdToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await apiClient.get(
        Uri.parse('$_baseUrl/api/store_settings/board_key?store_id=$storeId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'] as Map<String, dynamic>;
        return data['board_key'] as String;
      }
      throw Exception('Failed to fetch board key: ${response.body}');
    } catch (e) {
      rethrow;
    }
  }
}
