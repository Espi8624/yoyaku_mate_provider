import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/waiting_list.dart';

class WaitingService {
  static final WaitingService _instance = WaitingService._internal();
  final _waitingListController = StreamController<List<WaitingList>>.broadcast();
  bool _isConnected = false;
  Timer? _pollingTimer;
  static const String _baseUrl = 'http://localhost:8080';
  
  // 基本 polling 間隔と最大間隔設定
  static const Duration _minPollingInterval = Duration(seconds: 1);
  static const Duration _maxPollingInterval = Duration(seconds: 5);
  Duration _currentPollingInterval = _minPollingInterval;
  
  // 以前データキャッシュと変更検出用変数
  List<WaitingList>? _lastData;
  int _unchangedDataCount = 0;
  static const int _maxUnchangedCount = 5; // 5回連続データ変更がない場合、interval 増加

  factory WaitingService() {
    return _instance;
  }

  WaitingService._internal();

  Stream<List<WaitingList>> get waitingListStream => _waitingListController.stream;
  bool get isConnected => _isConnected;

  // 待機目録データを一度だけ取得する関数
  Future<List<WaitingList>> fetchWaitingCustomers({String storeId = 'store-001'}) async {
    try {
      // print('Fetching waiting customers from: $_baseUrl/api/waiting-list?store_id=$storeId');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/waiting-list?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // print('Decoded JSON: $jsonResponse');
        
        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          // print('Data list length: ${data.length}');
          return data.map((json) {
            try {
              return WaitingList.fromJson(json);
            } catch (e) {
              // print('Error parsing item: $json');
              // print('Parse error: $e');
              rethrow;
            }
          }).toList();
        } else {
          // print('Data field is null in response');
          return [];
        }
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } catch (e, _) {
      // print('Error fetching waiting customers: $e');
      // print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // polling 用データ取得関数
  Future<List<WaitingList>> _fetchWaitingListForPolling(String storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/waiting-list/poll?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      // print('Polling response status: ${response.statusCode}');
      // print('Polling response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        // print('Polling decoded JSON: $jsonResponse');
        
        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          // print('Polling data list length: ${data.length}');
          return data.map((json) {
            try {
              return WaitingList.fromJson(json);
            } catch (e) {
              // print('Error parsing polling item: $json');
              // print('Polling parse error: $e');
              rethrow;
            }
          }).toList();
        } else {
          // print('Data field is null in polling response');
          return [];
        }
      }
      throw Exception('Failed to fetch waiting list: ${response.statusCode}');
    } catch (e, _) {
      // print('Error fetching waiting list: $e');
      // print('Polling stack trace: $stackTrace');
      rethrow;
    }
  }

  bool _hasDataChanged(List<WaitingList> newData) {
    if (_lastData == null || _lastData!.length != newData.length) {
      return true;
    }

    // 整列されたリストで比較し、順序変更も検出
    final sortedLastData = List<WaitingList>.from(_lastData!)
      ..sort((a, b) => (a.waitingId).compareTo(b.waitingId));
    final sortedNewData = List<WaitingList>.from(newData)
      ..sort((a, b) => (a.waitingId).compareTo(b.waitingId));

    for (int i = 0; i < sortedNewData.length; i++) {
      final lastItem = sortedLastData[i];
      final newItem = sortedNewData[i];
      
      // 全てのフィールドを比較し、変更を検出
      if (lastItem.waitingId != newItem.waitingId ||
          lastItem.status != newItem.status ||
          lastItem.queueNumber != newItem.queueNumber ||
          lastItem.customerName != newItem.customerName ||
          lastItem.partySize != newItem.partySize ||
          lastItem.registrationTime != newItem.registrationTime ||
          lastItem.contact != newItem.contact ||
          lastItem.notes != newItem.notes ||
          lastItem.calledTime != newItem.calledTime ||
          lastItem.entryTime != newItem.entryTime) {
        return true;
      }
    }
    return false;
  }

  void _adjustPollingInterval(bool dataChanged) {
    if (dataChanged) {
      // データが変更された場合、即座に polling 間隔を最小に設定
      if (_currentPollingInterval != _minPollingInterval) {
        // print('Data changed, reducing polling interval to ${_minPollingInterval.inSeconds}s');
        _currentPollingInterval = _minPollingInterval;
        // polling タイマー再起動
        if (_lastStoreId != null) {
          _restartPolling(_lastStoreId!);
        }
      }
      _unchangedDataCount = 0;
    } else {
      _unchangedDataCount++;
      
      // 連続で5回以上変更がない場合、polling 間隔を徐々に増加
      if (_unchangedDataCount >= _maxUnchangedCount && 
          _currentPollingInterval < _maxPollingInterval) {
        final newInterval = _currentPollingInterval + const Duration(seconds: 1);
        if (newInterval <= _maxPollingInterval) {
          // print('No changes detected, increasing polling interval to ${newInterval.inSeconds}s');
          _currentPollingInterval = newInterval;
          // polling タイマー再起動
          if (_lastStoreId != null) {
            _restartPolling(_lastStoreId!);
          }
        }
        _unchangedDataCount = 0;
      }
    }
  }

  String? _lastStoreId;

  void _restartPolling(String storeId) {
    _pollingTimer?.cancel();
    _startPolling(storeId);
  }

  void startPolling({String storeId = 'store-001'}) {
    if (_isConnected && _lastStoreId == storeId) {
      // print('Already connected and polling for store: $storeId');
      return;
    }

    try {
      // print('Starting polling connection for store: $storeId');
      _isConnected = true;
      _lastStoreId = storeId;
      _startPolling(storeId);
    } catch (e, _) {
      // print('Polling connection error: $e');
      // print('Stack trace: $stackTrace');
      _isConnected = false;
      _waitingListController.addError(e);
    }
  }

  void _startPolling(String storeId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_currentPollingInterval, (timer) async {
      try {
        // print('Polling for updates (interval: ${_currentPollingInterval.inSeconds}s)...');
        final waitingList = await _fetchWaitingListForPolling(storeId);

        // データ変更検出
        final bool dataChanged = _hasDataChanged(waitingList);
        
        // polling 間隔調整
        _adjustPollingInterval(dataChanged);

        // 変更された場合のみストリームにデータを送信
        if (dataChanged) {
          // print('Data changed, sending update (${waitingList.length} items)');
          _waitingListController.add(waitingList);
          _lastData = waitingList;
        }
      } catch (e) {
        // print('Error during polling: $e');
        // エラー発生時、 polling 間隔を最小に再設定
        _currentPollingInterval = _minPollingInterval;
      }
    });
  }

  void stopPolling() {
    // print('Stopping polling service');
    _pollingTimer?.cancel();
    _isConnected = false;
    _lastData = null;
    _lastStoreId = null;
    _unchangedDataCount = 0;
    _currentPollingInterval = _minPollingInterval;
  }

  void dispose() {
    // print('Disposing waiting service');
    stopPolling();
    _waitingListController.close();
  }

   // 待機 ID 生成関数
  String _generateWaitingId() {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    
    return '$year$month$day-$hour$minute$second';
  }

  // 新規待機追加関数
  Future<WaitingList> createWaitingListItem({
    required String customerName,
    required int partySize,
    required String contact,
    required String nationality,
    String notes = '',
    String storeId = 'store-001',
  }) async {
    try {
      // print('Creating waiting list item with data:');  // Add debug log
      // print('customerName: $customerName');
      // print('partySize: $partySize');
      // print('nationality: $nationality');
      // print('contact: $contact');
      // print('notes: $notes');
      // print('storeId: $storeId');      // Generate waiting_id
      final waitingId = _generateWaitingId();

      // Create request body with required fields and waiting_id
      final Map<String, dynamic> requestBody = {
        'store_id': storeId,
        'waiting_id': waitingId,
        'customer_name': customerName,
        'party_size': partySize,
        'nationality': nationality,
        'contact': contact,
        'notes': notes,
        'status': 'waiting',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/waiting-list'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // print('Server response status: ${response.statusCode}');  // Add debug log
      // print('Server response body: ${response.body}');  // Add debug log

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final waitingList = WaitingList.fromJson(jsonResponse);
        
        // データが変更されたため、 polling 間隔を最小に再設定
        _currentPollingInterval = _minPollingInterval;
        if (_lastStoreId != null) {
          _restartPolling(_lastStoreId!);
        }
        
        return waitingList;
      }
      throw Exception('Failed to create waiting list item: ${response.statusCode}\nResponse: ${response.body}');
    } catch (e) {
      // print('Error creating waiting list item: $e');  // Add debug log
      rethrow;
    }
  }

  // 待機状態更新関数
  Future<void> updateWaitingStatus({
    required String waitingId,
    required String status,
    required String storeId,
  }) async {
    try {
      print('Updating waiting status - waitingId: $waitingId, status: $status, storeId: $storeId');
      
      final response = await http.patch(
        Uri.parse('$_baseUrl/api/waiting-list?action=status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'store_id': storeId,
          'waiting_id': waitingId,
          'status': status,
        }),
      );

      print('Server response status: ${response.statusCode}');
      print('Server response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update status: ${response.statusCode}');
      }

      // 強制に次に polling で新しいデータを取得するようにする
      _lastData = null;
      if (_pollingTimer != null) {
        _restartPolling(storeId);
      }
    } catch (e) {
      print('Error in updateWaitingStatus: $e');
      rethrow;
    }
  }

  // 待機目録初期化関数
  Future<void> clearWaitingList({String storeId = 'store-001'}) async {
    try {
      // print('Clearing waiting list for store: $storeId');
      // print('Request URL: $_baseUrl/api/waiting-list?action=clear&store_id=$storeId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/waiting-list?action=clear&store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
        body: '{}',  // 空 JSON Object 追加
      );

      // print('Clear waiting list response status: ${response.statusCode}');
      // print('Clear waiting list response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to clear waiting list: ${response.statusCode}');
      }

      // 초기화 후 즉시 데이터를 다시 가져와서 스트림에 전달
      // 初期化後、即データを再取得し、ストリームに送信
      final updatedList = await fetchWaitingCustomers(storeId: storeId);
      _waitingListController.add(updatedList);
      _lastData = updatedList;
    } catch (e) {
      // print('Error clearing waiting list: $e');
      rethrow;
    }
  }
}