import 'package:flutter/material.dart';
import 'dart:async';
import '../services/waiting_service.dart';
import '../models/waiting_list.dart';

class WaitingPage extends StatefulWidget {
  const WaitingPage({super.key});

  @override
  State<WaitingPage> createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  final WaitingService _waitingService = WaitingService();
  List<WaitingList> _waitingList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 초기 데이터 로드
      print('Fetching initial data...');
      final initialData = await _waitingService.fetchWaitingCustomers();
      
      if (!mounted) return;
      
      print('Received initial data: ${initialData.length} items');
      
      setState(() {
        _waitingList = initialData;
        _isLoading = false;
      });

      print('Initial data loaded, starting polling updates...');
      
      // polling 시작 및 실시간 업데이트 구독
      _waitingService.startPolling();
      _waitingService.waitingListStream.listen(
        (updatedList) {
          print('Received updated waiting list: ${updatedList.length} items');
          if (!mounted) return;
          setState(() {
            _waitingList = updatedList;
            _error = null;
          });
        },
        onError: (error) {
          print('Update stream error: $error');
          if (!mounted) return;
          setState(() {
            _error = 'リアルタイム更新中にエラーが発生しました: $error';
          });
        },
      );
    } catch (e) {
      print('Error in _initializeData: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'データの読み込み中にエラーが発生しました: $e';
      });
    }
  }

  @override
  void dispose() {
    print('Disposing WaitingPage');
    _waitingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 대기 리스트 (2/3 너비)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const WaitingListButtons(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(child: Text(_error!))
                            : WaitingListCard(waitingList: _waitingList),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            // 우측: 웨이팅 상태 (1/3 너비)
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QRCodeButtons(),
                  SizedBox(height: 10),
                  Expanded(
                    child: WaitingStatusArea(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 새로운 위젯: 대기 리스트 상단 버튼
class WaitingListButtons extends StatelessWidget {
  const WaitingListButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF263238),
          ),
          child: const Text(
            "新しい待機追加",
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text(
            "待機目録初期化",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class WaitingListCard extends StatelessWidget {
  final List<WaitingList> waitingList;

  const WaitingListCard({required this.waitingList, super.key});

  String _calculateWaitingTime(DateTime registrationTime) {
    final utcCurrentTime = DateTime.now().toUtc();
    final utcRegistrationTime = registrationTime.toUtc();
    final duration = utcCurrentTime.difference(utcRegistrationTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes分 $seconds秒';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            "待機中のお客様リスト",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
        ),
        Expanded(
          child: waitingList.isEmpty
              ? const Center(child: Text('待機中のお客様がいません。'))
              : ListView.builder(
                  itemCount: waitingList.length,
                  itemBuilder: (context, index) {
                    final item = waitingList[index];
                    final waitingTime = _calculateWaitingTime(item.registrationTime);
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "#${item.queueNumber}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFFFF6F61),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      "${item.customerName}様",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF263238),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Text(
                                      "${item.partySize}名",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFFFF6F61),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(
                                  height: 16,
                                  indent: 0,
                                  endIndent: 16,
                                  thickness: 0.2,
                                  color: Color(0xFF263238),
                                ),
                                Text(
                                  "待機時間　・・・　$waitingTime",
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF263238),
                                  minimumSize: const Size(75, 75),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.notifications_active_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// 새로운 위젯: 대기 리스트 상단 버튼
class QRCodeButtons extends StatelessWidget {
  const QRCodeButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF263238),
          ),
          child: const Row(
            children: [
              Icon(Icons.qr_code, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "QRコード",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WaitingStatusArea extends StatelessWidget {
  const WaitingStatusArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Text(
            "現状ウェイティング状況",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 16),
          // 상태 정보
          const Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatusInfo(label: "今から待機したら", value: "20分"),
              SizedBox(height: 8),
              _StatusInfo(label: "チーム当たり待機時間", value: "10分"),
              SizedBox(height: 8),
              _StatusInfo(label: "現在時間帯回転率", value: "3.0"),
            ],
          ),
          const SizedBox(height: 24),
          // 현재 웨이팅을 아래로 내리기 위해 Spacer 사용
          const Spacer(),
          // 현재 웨이팅 강조 상자
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 5),
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF263238),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF263238), width: 2),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 10),
                Text(
                  "現在待機チーム",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 55),
                    Text(
                      "2",
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6F61),
                      ),
                    ),
                    SizedBox(width: 16), // 숫자와 チーム 사이 간격
                    Text(
                      "チーム",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final String label;
  final String value;
  const _StatusInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6F61),
          ),
        ),
      ],
    );
  }
}
