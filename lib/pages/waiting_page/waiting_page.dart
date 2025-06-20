import 'package:flutter/material.dart';
import 'dart:async';

import 'buttons/waiting_list_button.dart';
import 'waiting_status_area.dart';
import 'buttons/QR_code_button.dart';
import 'waiting_list_card.dart';

import '../../services/waiting_service.dart';
import '../../models/waiting_list.dart';

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
      final initialData = await _waitingService.fetchWaitingCustomers();

      if (!mounted) return;

      setState(() {
        _waitingList = initialData;
        _isLoading = false;
      });

      // polling 시작 및 실시간 업데이트 구독
      _waitingService.startPolling();
      _waitingService.waitingListStream.listen(
        (updatedList) {
          if (!mounted) return;
          setState(() {
            _waitingList = updatedList;
            _error = null;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            if (error.toString().contains("data\":null")) {
              // 데이터가 없는 경우는 에러가 아닌 정상적인 상태로 처리
              _waitingList = [];
              _error = null;
            } else {
              _error = 'データの更新中にエラーが発生しました。しばらくしてからもう一度お試しください。';
            }
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.toString().contains("data\":null")) {
          // 데이터가 없는 경우는 에러가 아닌 정상적인 상태로 처리
          _waitingList = [];
          _error = null;
        } else {
          _error = 'データの読み込み中にエラーが発生しました。しばらくしてからもう一度お試しください。';
        }
      });
    }
  }

  @override
  void dispose() {
    // print('Disposing WaitingPage');
    _waitingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.only(
            top: 16.0, left: 16.0, bottom: 0.0, right: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 대기 리스트 (2/3 너비)
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WaitingListButtons(onRefresh: _initializeData),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _initializeData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF263238), // 배경색
                                        foregroundColor: Colors.white, // 글자색
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10), // 내부 여백
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              16), // 둥근 모서리
                                        ),
                                        elevation: 5, // 그림자 효과
                                      ),
                                      child: const Text('再試行'),
                                    ),
                                  ],
                                ),
                              )
                            : WaitingListCard(
                                waitingList: _waitingList,
                                onRefresh: _initializeData),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            // 우측: 웨이팅 상태 (1/3 너비)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const QRCodeButton(
                      data:
                          'https://1411-240b-10-bf67-3000-b4fa-8469-f2e4-80df.ngrok-free.app/wating-screen'),
                  const SizedBox(height: 10),
                  Expanded(
                    child: WaitingStatusArea(
                      waitingCount: _waitingList.length,
                      waitingList: _waitingList,
                    ),
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
