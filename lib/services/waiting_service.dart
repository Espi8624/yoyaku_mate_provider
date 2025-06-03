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
  
  // 기본 polling 간격과 최대 간격 설정
  static const Duration _minPollingInterval = Duration(seconds: 1);
  static const Duration _maxPollingInterval = Duration(seconds: 5);
  Duration _currentPollingInterval = _minPollingInterval;
  
  // 이전 데이터 캐시 및 변경 감지용 변수
  List<WaitingList>? _lastData;
  int _unchangedDataCount = 0;
  static const int _maxUnchangedCount = 5; // 5번 연속 데이터 변경 없으면 interval 증가

  factory WaitingService() {
    return _instance;
  }

  WaitingService._internal();

  Stream<List<WaitingList>> get waitingListStream => _waitingListController.stream;
  bool get isConnected => _isConnected;

  // 대기 목록 데이터를 한 번만 가져오는 함수
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
    } catch (e, stackTrace) {
      // print('Error fetching waiting customers: $e');
      // print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // 폴링용 데이터 가져오기 함수
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
    } catch (e, stackTrace) {
      // print('Error fetching waiting list: $e');
      // print('Polling stack trace: $stackTrace');
      rethrow;
    }
  }

  bool _hasDataChanged(List<WaitingList> newData) {
    if (_lastData == null || _lastData!.length != newData.length) {
      return true;
    }

    // 정렬된 리스트로 비교하여 순서 변경도 감지
    final sortedLastData = List<WaitingList>.from(_lastData!)
      ..sort((a, b) => (a.waitingId).compareTo(b.waitingId));
    final sortedNewData = List<WaitingList>.from(newData)
      ..sort((a, b) => (a.waitingId).compareTo(b.waitingId));

    for (int i = 0; i < sortedNewData.length; i++) {
      final lastItem = sortedLastData[i];
      final newItem = sortedNewData[i];
      
      // 모든 필드를 비교하여 변경 사항 감지
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
      // 데이터가 변경되었으면 즉시 polling 간격을 최소로 설정
      if (_currentPollingInterval != _minPollingInterval) {
        // print('Data changed, reducing polling interval to ${_minPollingInterval.inSeconds}s');
        _currentPollingInterval = _minPollingInterval;
        // polling 타이머 재시작
        if (_lastStoreId != null) {
          _restartPolling(_lastStoreId!);
        }
      }
      _unchangedDataCount = 0;
    } else {
      _unchangedDataCount++;
      
      // 연속 5번 이상 변경이 없으면 polling 간격을 점진적으로 증가
      if (_unchangedDataCount >= _maxUnchangedCount && 
          _currentPollingInterval < _maxPollingInterval) {
        final newInterval = _currentPollingInterval + const Duration(seconds: 1);
        if (newInterval <= _maxPollingInterval) {
          // print('No changes detected, increasing polling interval to ${newInterval.inSeconds}s');
          _currentPollingInterval = newInterval;
          // polling 타이머 재시작
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
    } catch (e, stackTrace) {
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

        // 데이터 변경 감지
        final bool dataChanged = _hasDataChanged(waitingList);
        
        // polling 간격 조정
        _adjustPollingInterval(dataChanged);

        // 변경된 경우에만 스트림에 데이터 전송
        if (dataChanged) {
          // print('Data changed, sending update (${waitingList.length} items)');
          _waitingListController.add(waitingList);
          _lastData = waitingList;
        }
      } catch (e) {
        // print('Error during polling: $e');
        // 에러 발생 시 polling 간격을 최소로 재설정
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

  // 새로운 대기 추가 함수
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
      // print('storeId: $storeId');

      // Create request body with only required fields
      final Map<String, dynamic> requestBody = {
        'store_id': storeId,
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
        
        // 데이터가 변경되었으므로 polling 간격을 최소로 재설정
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

  // 대기 목록 초기화 함수
  Future<void> clearWaitingList({String storeId = 'store-001'}) async {
    try {
      // print('Clearing waiting list for store: $storeId');
      // print('Request URL: $_baseUrl/api/waiting-list?action=clear&store_id=$storeId');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/waiting-list?action=clear&store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
        body: '{}',  // 빈 JSON 객체 추가
      );

      // print('Clear waiting list response status: ${response.statusCode}');
      // print('Clear waiting list response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to clear waiting list: ${response.statusCode}');
      }

      // 초기화 후 즉시 데이터를 다시 가져와서 스트림에 전달
      final updatedList = await fetchWaitingCustomers(storeId: storeId);
      _waitingListController.add(updatedList);
      _lastData = updatedList;
    } catch (e) {
      // print('Error clearing waiting list: $e');
      rethrow;
    }
  }
}