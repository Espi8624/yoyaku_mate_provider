import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
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
    print('Disposing WaitingPage');
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
                  const WaitingListButtons(),
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
                  const QRCodeButtons(),
                  const SizedBox(height: 10),
                  Expanded(
                    child: WaitingStatusArea(waitingCount: _waitingList.length),
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
    final waitingPageState =
        context.findAncestorStateOfType<_WaitingPageState>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AddWaitingDialog(
                onAddSuccess: waitingPageState!._initializeData,
              ),
            );
          },
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
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                // 다이얼로그 배경색
                backgroundColor: Colors.white,
                // 다이얼로그 모양 (둥근 모서리)
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  '待機目録初期化',
                  style: TextStyle(
                      color: Color(0xFF263238), fontWeight: FontWeight.bold),
                ),
                content: const Text('現在の待機目録を全て初期化しますか？\nこの操作は取り消しできません。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.grey[200];
                          }
                          return null;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.grey[600] ?? Colors.grey;
                          }
                          return Colors.grey[400] ?? Colors.grey;
                        },
                      ),
                    ),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        final waitingService = WaitingService();
                        await waitingService.clearWaitingList();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('待機目録を初期化しました。'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('待機目録の初期化に失敗しました。'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('初期化'),
                  ),
                ],
              ),
            );
          },
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

class AddWaitingDialog extends StatefulWidget {
  final VoidCallback onAddSuccess;

  const AddWaitingDialog({super.key, required this.onAddSuccess});

  @override
  State<AddWaitingDialog> createState() => _AddWaitingDialogState();
}

class _AddWaitingDialogState extends State<AddWaitingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _partySizeController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _selectedNationality;

  @override
  void initState() {
    super.initState();
    _selectedNationality = "日本";
    _nationalityController.text = _selectedNationality ?? '';
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _partySizeController.dispose();
    _nationalityController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final waitingService = WaitingService();
      await waitingService.createWaitingListItem(
        customerName: _customerNameController.text,
        partySize: int.parse(_partySizeController.text),
        nationality: _nationalityController.text,
        contact: _contactController.text,
        notes: _notesController.text,
        storeId: 'store-001',
      );

      if (!mounted) return;

      widget.onAddSuccess();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('待機が正常に追加されました。'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      print('Error in _submitForm: $e');

      if (!mounted) return;

      if (e.toString().contains('Failed to create waiting list item')) {
        setState(() {
          _error = 'エラー: データの保存に失敗しました。';
          _isLoading = false;
        });
      } else {
        widget.onAddSuccess();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '新しい待機追加',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _customerNameController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: 'お客様名',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'お客様名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _partySizeController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: '人数',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '人数を入力してください';
                  }
                  if (int.tryParse(value) == null) {
                    return '有効な数字を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: '連絡先',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '連絡先を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownSearch<String>(
                asyncItems: (String? filter) async {
                  try {
                    final String response = await DefaultAssetBundle.of(context)
                        .loadString('assets/nationalities.json');
                    final data = json.decode(response);
                    List<String> nationalities =
                        List<String>.from(data['nationalities']);

                    if (filter != null && filter.isNotEmpty) {
                      nationalities = nationalities
                          .where((item) =>
                              item.toLowerCase().contains(filter.toLowerCase()))
                          .toList();
                    }

                    print(
                        'Loaded ${nationalities.length} nationalities for filter: $filter');
                    return nationalities;
                  } catch (e) {
                    print('Error loading nationalities: $e');
                    return ['データ読み込みエラー'];
                  }
                },
                selectedItem: _selectedNationality,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedNationality = newValue;
                    _nationalityController.text = newValue ?? '';
                  });
                },
                enabled: true,
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    labelText: '国籍',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF263238), width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    labelStyle: TextStyle(color: Color(0xFF263238)),
                    floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: '国籍を検索',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                  constraints:
                      const BoxConstraints(maxHeight: 300, maxWidth: 350),
                  listViewProps: const ListViewProps(
                    physics: ClampingScrollPhysics(),
                    cacheExtent: 1000.0,
                  ),
                  // dialogProps: const DialogProps(
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.all(Radius.circular(12)),
                  //   ),
                  // ),
                  emptyBuilder: (context, searchEntry) => const Center(
                    child: Text('データが見つかりません'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                cursorColor: const Color(0xFF263238),
                decoration: const InputDecoration(
                  labelText: '要望事項',
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF263238), width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  labelStyle: TextStyle(color: Color(0xFF263238)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF263238)),
                ),
                style: const TextStyle(color: Color(0xFF263238)),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.grey[200];
                          }
                          return null;
                        },
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Colors.grey[600] ?? Colors.grey;
                          }
                          return Colors.grey[400] ?? Colors.grey;
                        },
                      ),
                    ),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F61),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            '追加',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaitingListCard extends StatefulWidget {
  final List<WaitingList> waitingList;
  final VoidCallback onRefresh;

  const WaitingListCard(
      {required this.waitingList, required this.onRefresh, super.key});

  @override
  State<WaitingListCard> createState() => _WaitingListCardState();
}

class _WaitingListCardState extends State<WaitingListCard> {
  Timer? _timer;
  final Map<String, String> _waitingTimes = {};

  @override
  void initState() {
    super.initState();
    _updateWaitingTimes();
    // 1초마다 대기 시간 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateWaitingTimes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(WaitingListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 위젯이 업데이트될 때(새로운 데이터가 들어올 때) 대기 시간도 업데이트
    _updateWaitingTimes();
  }

  void _updateWaitingTimes() {
    if (!mounted) return;

    setState(() {
      for (var item in widget.waitingList) {
        _waitingTimes[item.waitingId] =
            _calculateWaitingTime(item.registrationTime);
      }
    });
  }

  String _calculateWaitingTime(DateTime registrationTime) {
    final currentTime = DateTime.now();
    final duration = currentTime.difference(registrationTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes分 $seconds秒';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                "待機中のお客様リスト",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'リスト更新',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF263238),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.waitingList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '待機中のお客様がいません。',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.waitingList.length,
                  itemBuilder: (context, index) {
                    final item = widget.waitingList[index];
                    final waitingTime = _waitingTimes[item.waitingId] ??
                        _calculateWaitingTime(item.registrationTime);
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
                                      "${item.customerName} 様",
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
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  "備考　　　・・・　${item.notes}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  print('通知ボタンが押されました${item.waitingId}');
                                },
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
  final int waitingCount;
  const WaitingStatusArea({super.key, required this.waitingCount});

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
              _StatusInfo(label: "本日混雑予想時間帯", value: "13時"),
              SizedBox(height: 8),
              _StatusInfo(label: "直前入場時間", value: "12:40"),
              SizedBox(height: 8),
              _StatusInfo(label: "平均待機時間", value: "10分"),
              SizedBox(height: 8),
              _StatusInfo(label: "現在時間帯回転率", value: ""),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "今後追加される予定です",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
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
                    const SizedBox(width: 55),
                    Text(
                      waitingCount.toString(),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6F61),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
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
