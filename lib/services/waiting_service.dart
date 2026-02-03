import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waiting_list.dart';

class WaitingService {
  static final WaitingService _instance = WaitingService._internal();
  late StreamController<List<WaitingList>> _waitingListController;
  bool _isConnected = false;
  static const String _baseUrl = 'https://saboten-server.fly.dev';

  // SSE接続クライアント
  http.Client? _client;
  String? _lastStoreId;

  // 再接続用変数
  Timer? _reconnectTimer;
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
      final response = await http.get(
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
    connectToStream(storeId);
  }

  void connectToStream(String storeId) {
    if (_isConnected && _lastStoreId == storeId) return;

    _client?.close();
    _reconnectTimer?.cancel();
    _client = http.Client();
    _lastStoreId = storeId;
    _isConnected = true;

    // print('店舗のSSEストリームに接続: $storeId');

    final request = http.Request(
      'GET',
      Uri.parse('$_baseUrl/api/waiting-list/stream?store_id=$storeId'),
    );
    request.headers['Cache-Control'] = 'no-cache';
    request.headers['Accept'] = 'text/event-stream';

    _client!.send(request).then((response) {
      if (response.statusCode == 200) {
        response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              try {
                // print('SSEデータ受信: $data');
                final List<dynamic> jsonList = json.decode(data);
                final waitingList =
                    jsonList.map((item) => WaitingList.fromJson(item)).toList();
                _waitingListController.add(waitingList);
              } catch (e) {
                // print('SSEデータパースエラー: $e');
              }
            }
          },
          onError: (e) {
            // print('SSEストリームエラー: $e');
            _handleDisconnect(storeId);
          },
          onDone: () {
            // print('SSEストリーム切断');
            _handleDisconnect(storeId);
          },
          cancelOnError: true,
        );
      } else {
        // print('SSEストリーム接続失敗: ${response.statusCode}');
        _handleDisconnect(storeId);
      }
    }).catchError((e) {
      // print('接続エラー: $e');
      _handleDisconnect(storeId);
    });
  }

  void _handleDisconnect(String storeId) {
    if (!_isConnected) return; // 手動で停止済み

    _isConnected = false;
    _isConnected = false;

    // 遅延後に再接続
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      // print('再接続を試行中...');
      connectToStream(storeId);
    });
  }

  void stopPolling() {
    _isConnected = false;
    _client?.close();
    _client = null;
    _reconnectTimer?.cancel();
    _reconnectTimer?.cancel();
    _lastStoreId = null;
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

  // Helper to get Login Token
  Future<String?> _getLoginToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('login_token');
    // print(
    //     '--- [WaitingService] Read Token: ${token != null ? token.substring(0, 5) + "..." : "NULL"} ---');
    return token;
  }

  // 新規待機追加
  Future<WaitingList> createWaitingListItem({
    required int partySize,
    required String contact,
    required String nationality,
    String notes = '',
    required String storeId,
    String? vToken, // Added vToken parameter
    List<MenuItem>? menuItems,
  }) async {
    try {
      // WaitingID is now generated by the server

      final Map<String, dynamic> requestBody = {
        'store_id': storeId,
        // 'waiting_id': waitingId, // Removed: handled by server
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

        // Add Login Token
        final loginToken = await _getLoginToken();
        if (loginToken != null) {
          headers['X-Login-Token'] = loginToken;
        }
      } catch (e) {
        // print('未認証、Authヘッダーなしで続行');
      }

      // Add vToken to query parameters if present
      final uri = Uri.parse('$_baseUrl/api/waiting-list').replace(
          queryParameters: vToken != null ? {'v_token': vToken} : null);

      final response = await http.post(
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
      final loginToken = await _getLoginToken(); // Get Login Token

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      if (loginToken != null) {
        headers['X-Login-Token'] = loginToken;
      }

      final response = await http.patch(
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
      final loginToken = await _getLoginToken(); // Get Login Token

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      if (loginToken != null) {
        headers['X-Login-Token'] = loginToken;
      }

      final response = await http.post(
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

  // QRトークン取得
  Future<Map<String, String>> fetchQRToken(String storeId) async {
    try {
      final token = await _getIdToken();
      final loginToken =
          await _getLoginToken(); // Get Login Token (Optional but good practice)

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      if (loginToken != null) {
        headers['X-Login-Token'] = loginToken;
      }

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/waiting-list?action=qr_token&store_id=$storeId'),
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
}
