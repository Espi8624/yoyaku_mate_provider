import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/gestures.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _categoryNameController = TextEditingController();
  List<String> categories = [];
  Map<String, List<Map<String, dynamic>>> categorizedMenu = {};
  late TabController _tabController;

  // 메뉴 입력 컨트롤러
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  Uint8List? selectedImageBytes;

  // 수평 스크롤을 위한 ScrollController
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryNameController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _updateTabController() {
    final currentIndex = _tabController.index;
    _tabController.dispose();
    _tabController = TabController(
      length: categories.length,
      vsync: this,
      initialIndex:
          categories.isEmpty ? 0 : currentIndex.clamp(0, categories.length - 1),
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  // 카테고리 추가 다이얼로그
  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Center(
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _categoryNameController.clear();
                        },
                        icon: const Icon(Icons.close, color: Color(0xFF263238)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const Text(
                      "カテゴリー追加",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _categoryNameController,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリー名',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF263238),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final categoryName =
                              _categoryNameController.text.trim();
                          if (categoryName.isNotEmpty &&
                              !categories.contains(categoryName)) {
                            setState(() {
                              categories.add(categoryName);
                              categorizedMenu[categoryName] = [];
                              _updateTabController();
                              _tabController.index = categories.length - 1;
                            });
                          }
                          Navigator.of(context).pop();
                          _categoryNameController.clear();
                        },
                        child: const Text("確認"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 카테고리 수정 다이얼로그
  void _showEditCategoryDialog(int index) {
    _categoryNameController.text = categories[index]; // 기존 카테고리 이름으로 초기화
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Center(
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _categoryNameController.clear();
                        },
                        icon: const Icon(Icons.close, color: Color(0xFF263238)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const Text(
                      "カテゴリー編集",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _categoryNameController,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリー名',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF263238),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          final newCategoryName =
                              _categoryNameController.text.trim();
                          if (newCategoryName.isNotEmpty &&
                              !categories.contains(newCategoryName)) {
                            setState(() {
                              // 기존 카테고리 이름
                              final oldCategoryName = categories[index];
                              // 카테고리 이름 업데이트
                              categories[index] = newCategoryName;
                              // categorizedMenu에서 키 업데이트
                              final menuList =
                                  categorizedMenu[oldCategoryName] ?? [];
                              categorizedMenu.remove(oldCategoryName);
                              categorizedMenu[newCategoryName] = menuList;
                              _updateTabController();
                            });
                          }
                          Navigator.of(context).pop();
                          _categoryNameController.clear();
                        },
                        child: const Text("確認"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 메뉴 추가 다이얼로그
  Future<Map<String, dynamic>?> _showAddMenuDialog() {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Center(
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 500,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop(null);
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF263238),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const Text(
                            "メニュー追加",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              if (result != null &&
                                  result.files.single.bytes != null) {
                                setState(() {
                                  selectedImageBytes =
                                      result.files.single.bytes!;
                                });
                              }
                            },
                            child: DottedBorder(
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(8),
                              dashPattern: const [6, 3],
                              color: Colors.grey,
                              strokeWidth: 1.5,
                              child: SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: selectedImageBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          selectedImageBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : const Center(
                                        child: Text(
                                          '+ クリックして画像を選択',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'メニュー名',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: '説明',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '価格',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF263238),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('メニュー名を入力してください。'),
                                    ),
                                  );
                                  return;
                                }
                                final menuItem = {
                                  "image": selectedImageBytes,
                                  "title": titleController.text,
                                  "description": descriptionController.text,
                                  "price": priceController.text,
                                };
                                Navigator.of(context).pop(menuItem);
                              },
                              child: const Text("確認"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 메뉴 수정 다이얼로그
  Future<Map<String, dynamic>?> _showEditMenuDialog(
      int categoryIndex, int menuIndex) {
    final category = categories[categoryIndex];
    final menuItem = categorizedMenu[category]![menuIndex];

    // 기존 값으로 컨트롤러 초기화
    selectedImageBytes = menuItem['image'];
    titleController.text = menuItem['title'] ?? '';
    descriptionController.text = menuItem['description'] ?? '';
    priceController.text = menuItem['price'] ?? '';

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Center(
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: 500,
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop(null);
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Color(0xFF263238),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const Text(
                            "メニュー編集",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              if (result != null &&
                                  result.files.single.bytes != null) {
                                setState(() {
                                  selectedImageBytes =
                                      result.files.single.bytes!;
                                });
                              }
                            },
                            child: DottedBorder(
                              borderType: BorderType.RRect,
                              radius: const Radius.circular(8),
                              dashPattern: const [6, 3],
                              color: Colors.grey,
                              strokeWidth: 1.5,
                              child: SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: selectedImageBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          selectedImageBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        ),
                                      )
                                    : const Center(
                                        child: Text(
                                          '+ クリックして画像を選択',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'メニュー名',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: '説明',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '価格',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF263238),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('メニュー名を入力してください。'),
                                    ),
                                  );
                                  return;
                                }
                                final updatedMenuItem = {
                                  "image": selectedImageBytes,
                                  "title": titleController.text,
                                  "description": descriptionController.text,
                                  "price": priceController.text,
                                };
                                Navigator.of(context).pop(updatedMenuItem);
                              },
                              child: const Text("確認"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addMenu() async {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先にカテゴリーを追加してください。')),
      );
      return;
    }

    final newMenu = await _showAddMenuDialog();
    if (newMenu != null) {
      final currentCategory = categories[_tabController.index];
      setState(() {
        categorizedMenu[currentCategory]?.add(newMenu);
      });

      // 선택 초기화
      selectedImageBytes = null;
      titleController.clear();
      descriptionController.clear();
      priceController.clear();
    }
  }

  // 메뉴 수정 기능
  Future<void> _editMenu(int categoryIndex, int menuIndex) async {
    final updatedMenu = await _showEditMenuDialog(categoryIndex, menuIndex);
    if (updatedMenu != null) {
      final category = categories[categoryIndex];
      setState(() {
        categorizedMenu[category]![menuIndex] = updatedMenu;
      });

      // 선택 초기화
      selectedImageBytes = null;
      titleController.clear();
      descriptionController.clear();
      priceController.clear();
    }
  }

  void _showDeleteCategoryDialog(int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("削除"),
          content: const Text("このカテゴリーを削除しますか？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("キャンセル"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final category = categories[index];
                  categories.removeAt(index);
                  categorizedMenu.remove(category);
                  _updateTabController();

                  if (_tabController.index >= categories.length &&
                      categories.isNotEmpty) {
                    _tabController.index =
                        categories.isNotEmpty ? categories.length - 1 : 0;
                  }
                });
                Navigator.of(context).pop();
              },
              child: const Text(
                "削除",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteMenuDialog(int categoryIndex, int menuIndex) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("確認"),
        content: const Text("本当にこのメニューを削除しますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final category = categories[categoryIndex];
                categorizedMenu[category]?.removeAt(menuIndex);
              });
              Navigator.of(context).pop();
            },
            child: const Text("削除"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Row(
          children: [
            // 왼쪽 메인 영역: 타이틀 + 탭 + 메뉴 리스트
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "メニュー管理",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                  ),
                  if (categories.isNotEmpty)
                    SizedBox(
                      height: 60,
                      child: Listener(
                        // 마우스 휠 이벤트 감지
                        onPointerSignal: (PointerSignalEvent event) {
                          if (event is PointerScrollEvent) {
                            final delta = event.scrollDelta.dy;
                            if (_scrollController.hasClients) {
                              final maxExtent =
                                  _scrollController.position.maxScrollExtent;
                              final newOffset =
                                  (_scrollController.offset + delta)
                                      .clamp(0.0, maxExtent);
                              _scrollController.animateTo(
                                newOffset,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.ease,
                              );
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children:
                                  List.generate(categories.length, (index) {
                                final isSelected =
                                    _tabController.index == index;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF263238)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: const Color(0xFF263238),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _tabController.index = index;
                                            });
                                          },
                                          child: Text(
                                            categories[index],
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF263238),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            _showEditCategoryDialog(
                                                index); // 수정 버튼
                                          },
                                          child: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            _showDeleteCategoryDialog(
                                                index); // 삭제 버튼
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (categories.isNotEmpty)
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: categories.map((category) {
                          final menuList = categorizedMenu[category] ?? [];
                          return ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: menuList.length,
                            itemBuilder: (context, index) {
                              final menuItem = menuList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                color: const Color(0xFFFFFFFF),
                                elevation: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100], // 배경색 유지
                                    borderRadius: BorderRadius.circular(
                                        8), // Card의 모서리 반경과 일치
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.15), // 그림자 색상
                                        spreadRadius: 1, // 그림자 퍼짐 정도
                                        blurRadius: 3, // 그림자 흐림 정도
                                        offset: const Offset(
                                            1, 1), // 그림자 위치 (오른쪽 아래로 이동)
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: menuItem['image'] != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.memory(
                                                menuItem['image'],
                                                fit: BoxFit.cover,
                                                width: 50,
                                                height: 50,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    title: Text(menuItem['title'] ?? ''),
                                    subtitle:
                                        Text(menuItem['description'] ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${menuItem['price']}円'),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            _editMenu(_tabController.index,
                                                index); // 수정 버튼
                                          },
                                          child: const Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            _showDeleteMenuDialog(
                                                _tabController.index,
                                                index); // 삭제 버튼
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 18,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  if (categories.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'カテゴリーを追加してください。',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 구분선
            Container(
              width: 1,
              color: Colors.grey[300],
            ),

            // 오른쪽 사이드바: 버튼들
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "メニュー管理ボタン",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: SizedBox(
                        width: 270,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF263238),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _showAddCategoryDialog,
                          child: const Text("カテゴリー追加"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 270,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF263238),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: categories.isEmpty ? null : _addMenu,
                          child: const Text("メニュー追加"),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: SizedBox(
                        width: 270,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF263238),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // 저장 로직 (여기서는 단순히 메시지 표시)
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     content: Text('データを保存しました。'),
                            //   ),
                            // );
                          },
                          child: const Text("保存"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 270,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.redAccent, // 초기화 버튼은 빨간색으로 구분
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            // 초기화 로직
                            setState(() {
                              categories.clear();
                              categorizedMenu.clear();
                              _updateTabController();
                            });
                            // ScaffoldMessenger.of(context).showSnackBar(
                            //   const SnackBar(
                            //     content: Text('データを初期化しました。'),
                            //   ),
                            // );
                          },
                          child: const Text("初期化"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
