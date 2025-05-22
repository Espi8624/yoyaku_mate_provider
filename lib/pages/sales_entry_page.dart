import 'dart:async';

import 'package:flutter/material.dart';

class SalesEntryPage extends StatefulWidget {
  const SalesEntryPage({super.key});

  @override
  State<SalesEntryPage> createState() => _SalesEntryPageState();
}

class _SalesEntryPageState extends State<SalesEntryPage> {
  // 폼 컨테이너 리스트 관리
  final List<Map<String, dynamic>> formItems = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 초기 폼 하나 추가
    _addNewFormContainer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 새로운 폼 추가 메서드
  void _addNewFormContainer() {
    final String formKey = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      formItems.add({'formKey': formKey});
    });

    // 폼 추가 후 스크롤 자동 이동
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeFormContainer(String formKey) {
    setState(() {
      formItems.removeWhere((item) => item['formKey'] == formKey);
    });
  }

  // 단일 폼 컨테이너 생성
  Widget _buildSingleFormContainer(String formKey, {Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
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
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildFormField("商品名", "商品名を入力"),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildFormField("数量", "数量を入力"),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildFormField("単価", "単価を入力"),
              ),
            ],
          ),

          // 삭제 버튼
          Positioned(
            top: -10,
            right: -10,
            child: IconButton(
              onPressed: () => _removeFormContainer(formKey),
              icon: const Icon(
                Icons.cancel,
                color: Colors.red,
                size: 24,
              ),
              tooltip: "Remove Item",
              splashRadius: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // 왼쪽: 매상 입력 폼 (2)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀
                  const Text(
                    "売上入力",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),

                  // 날짜 선택
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        "日付",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "2024/04/24",
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today,
                                size: 20, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 추가 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _addNewFormContainer, // 여기서 폼 추가
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF263238),
                          size: 37,
                        ),
                        tooltip: "Add Item",
                      ),
                    ],
                  ),

                  // 입력 폼 영역 (스크롤 가능)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
      children: formItems
          .map((item) => _buildSingleFormContainer(item['formKey'] as String, key: ValueKey(item['formKey'])))
          .toList(),
    ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263238),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "保存",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 구분선
          Container(
            width: 1,
            color: Colors.grey[300],
          ),

          // 오른쪽: 매상 확인 (1)
          Expanded(
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "本日の売上",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "チャミスル",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "2 × 800",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "¥1600",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 구분선 추가
                  const Divider(height: 32, thickness: 1),
                  // 합계 영역 추가
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "合計",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF263238),
                          ),
                        ),
                        Text(
                          "¥16,000",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6F61),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String hint, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
