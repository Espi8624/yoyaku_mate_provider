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
      print('Fetching waiting customers from: $_baseUrl/api/waiting-list?store_id=$storeId');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/waiting-list?store_id=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => WaitingList.fromJson(json)).toList();
        }
      }
      throw Exception('Server returned ${response.statusCode}: ${response.body}');
    } catch (e) {
      print('Error fetching waiting customers: $e');
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

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => WaitingList.fromJson(json)).toList();
        }
      }
      throw Exception('Failed to fetch waiting list: ${response.statusCode}');
    } catch (e) {
      print('Error fetching waiting list: $e');
      rethrow;
    }
  }

  void startPolling({String storeId = 'store-001'}) {
    if (_isConnected) {
      print('Already connected and polling');
      return;
    }

    try {
      print('Starting polling connection...');
      _isConnected = true;
      _startPolling(storeId);
    } catch (e, stackTrace) {
      print('Polling connection error: $e');
      print('Stack trace: $stackTrace');
      _isConnected = false;
      _waitingListController.addError(e);
    }
  }

  bool _hasDataChanged(List<WaitingList> newData) {
    if (_lastData == null || _lastData!.length != newData.length) {
      return true;
    }

    // 간단한 비교: 각 항목의 ID와 상태만 비교
    for (int i = 0; i < newData.length; i++) {
      if (_lastData![i].id != newData[i].id ||
          _lastData![i].status != newData[i].status ||
          _lastData![i].queueNumber != newData[i].queueNumber) {
        return true;
      }
    }
    return false;
  }

  void _adjustPollingInterval(bool dataChanged) {
    if (dataChanged) {
      // 데이터가 변경되었으면 polling 간격을 최소로 줄임
      if (_currentPollingInterval != _minPollingInterval) {
        print('Data changed, reducing polling interval to ${_minPollingInterval.inSeconds}s');
        _currentPollingInterval = _minPollingInterval;
      }
      _unchangedDataCount = 0;
    } else {
      // 데이터 변경이 없으면 카운트 증가
      _unchangedDataCount++;
      
      // 일정 횟수 이상 변경이 없으면 polling 간격을 늘림
      if (_unchangedDataCount >= _maxUnchangedCount && 
          _currentPollingInterval < _maxPollingInterval) {
        _currentPollingInterval += const Duration(seconds: 1);
        print('No changes detected, increasing polling interval to ${_currentPollingInterval.inSeconds}s');
        _unchangedDataCount = 0;
      }
    }
  }

  void _startPolling(String storeId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_currentPollingInterval, (timer) async {
      try {
        print('Polling for updates (interval: ${_currentPollingInterval.inSeconds}s)...');
        final waitingList = await _fetchWaitingListForPolling(storeId);

        // 데이터 변경 감지
        final bool dataChanged = _hasDataChanged(waitingList);
        
        // polling 간격 조정
        _adjustPollingInterval(dataChanged);

        // 변경된 경우에만 스트림에 데이터 전송
        if (dataChanged) {
          print('Data changed, sending update (${waitingList.length} items)');
          _waitingListController.add(waitingList);
          _lastData = waitingList;
        }
      } catch (e) {
        print('Error during polling: $e');
        // 에러 발생 시 polling 간격을 최소로 재설정
        _currentPollingInterval = _minPollingInterval;
      }
    });
  }

  void stopPolling() {
    print('Stopping polling service');
    _pollingTimer?.cancel();
    _isConnected = false;
    _lastData = null;
    _unchangedDataCount = 0;
    _currentPollingInterval = _minPollingInterval;
  }

  void dispose() {
    print('Disposing waiting service');
    stopPolling();
    _waitingListController.close();
  }
}