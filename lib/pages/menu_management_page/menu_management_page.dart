import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/add_category_dialog.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/add_menu_dialog.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/edit_category_dialog.dart';
import 'package:yoyaku_mate_provider/pages/menu_management_page/widgets/menu_management_page_loading.dart';
import '../../models/menu_list.dart';
import '../../services/menu_service.dart';
import '../menu_management_page/widgets/edit_menu_dialog.dart';

class MenuManagementPage extends StatefulWidget {
  const MenuManagementPage({super.key});

  @override
  State<MenuManagementPage> createState() => _MenuManagementPageState();
}

class _MenuManagementPageState extends State<MenuManagementPage>
    with TickerProviderStateMixin {
  final TextEditingController _categoryNameController = TextEditingController();
  List<String> categories = [];
  List<MenuListItem> menuItems = []; // 상태 변수 추가
  Map<String, List<MenuListItem>> categorizedMenu = {};
  late TabController _tabController;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  Map<String, List<MenuListItem>> _originalMenuData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _tabController.previousIndex) {
        setState(() {});
      }
    });
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    setState(() => _isLoading = true);
    try {
      final fetchedMenuItems =
          await MenuService().fetchMenuItems(storeId: 'store-001');
      setState(() {
        menuItems = fetchedMenuItems;
        _updateCategorizedMenu();
        _updateTabController();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メニューの取得に失敗しました: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateCategorizedMenu() {
    final Map<String, List<MenuListItem>> newCategorizedMenu = {};
    for (var item in menuItems) {
      final category = item.category.isNotEmpty ? item.category : '未分類';
      if (!newCategorizedMenu.containsKey(category)) {
        newCategorizedMenu[category] = [];
      }
      newCategorizedMenu[category]!.add(item);
    }
    categorizedMenu = newCategorizedMenu;
    _originalMenuData = Map.from(newCategorizedMenu);
    categories = newCategorizedMenu.keys.toList();
  }

  bool hasChanges() {
    // 1. 카테고리 키 비교
    final originalCategories = _originalMenuData.keys.toSet();
    final currentCategories = categorizedMenu.keys.toSet();
    if (originalCategories != currentCategories) return true;

    // 2. 각 카테고리별 메뉴 항목 비교
    for (var category in categorizedMenu.keys) {
      final originalItems = _originalMenuData[category] ?? [];
      final currentItems = categorizedMenu[category] ?? [];

      // 2.1 메뉴 항목 길이 비교
      if (originalItems.length != currentItems.length) return true;

      // 2.2 메뉴 항목을 ID로 매핑
      final originalItemsMap = {
        for (var item in originalItems)
          item.id.isNotEmpty ? item.id : item.menuId: item
      };
      final currentItemsMap = {
        for (var item in currentItems)
          item.id.isNotEmpty ? item.id : item.menuId: item
      };

      // 2.3 ID가 다른 경우 (추가/삭제)
      if (originalItemsMap.keys.toSet() != currentItemsMap.keys.toSet())
        return true;

      // 2.4 각 항목별 속성 비교
      for (var id in currentItemsMap.keys) {
        final originalItem = originalItemsMap[id];
        final currentItem = currentItemsMap[id];
        if (originalItem == null || currentItem == null) return true;

        // 새로 추가된 항목 (id가 빈 문자열)
        if (currentItem.id.isEmpty && currentItem.menuId.isEmpty) return true;

        if (currentItem.title != originalItem.title ||
            currentItem.description != originalItem.description ||
            currentItem.price != originalItem.price ||
            currentItem.menuStatus != originalItem.menuStatus ||
            currentItem.category != originalItem.category ||
            currentItem.tempImageBytes != null) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _saveChanges() async {
    bool changesDetected = hasChanges();
    print('Changes detected: $changesDetected');
    if (!changesDetected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('変更がありません。')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 메뉴 저장
      await MenuService().saveMenuItems(categorizedMenu, 'store-001');

      // 서버에서 최신 데이터 가져오기 (새로고침)
      final updatedMenuItems =
          await MenuService().fetchMenuItems(storeId: 'store-001');

      setState(() {
        menuItems = updatedMenuItems;
        _updateCategorizedMenu();
        _updateTabController();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全てのメニューが保存され、更新されました。')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('メニューの保存または更新に失敗しました: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      if (_tabController.index != _tabController.previousIndex) {
        setState(() {});
      }
    });
  }

  void _showEditCategoryDialog(int index) {
    _categoryNameController.text = categories[index];
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return EditCategoryDialog(
          controller: _categoryNameController,
          onEditCategory: (newCategoryName) {
            setState(() {
              final oldCategoryName = categories[index];
              categories[index] = newCategoryName;
              final menuList = categorizedMenu[oldCategoryName] ?? [];
              categorizedMenu[newCategoryName] = menuList.map((item) {
                return MenuListItem(
                  id: item.id,
                  storeId: item.storeId,
                  menuId: item.menuId,
                  category: newCategoryName,
                  title: item.title,
                  description: item.description,
                  price: item.price,
                  imageUrl: item.imageUrl,
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now(),
                  menuStatus: item.menuStatus,
                  tempImageBytes: item.tempImageBytes,
                );
              }).toList();
              categorizedMenu.remove(oldCategoryName);

              // _originalMenuData 동기화
              final originalMenuList = _originalMenuData[oldCategoryName] ?? [];
              _originalMenuData[newCategoryName] = originalMenuList;
              _originalMenuData.remove(oldCategoryName);

              // menuItems 동기화
              for (var item in menuItems) {
                if (item.category == oldCategoryName) {
                  final itemIndex = menuItems.indexOf(item);
                  menuItems[itemIndex] = MenuListItem(
                    id: item.id,
                    storeId: item.storeId,
                    menuId: item.menuId,
                    category: newCategoryName,
                    title: item.title,
                    description: item.description,
                    price: item.price,
                    imageUrl: item.imageUrl,
                    createdAt: item.createdAt,
                    updatedAt: DateTime.now(),
                    menuStatus: item.menuStatus,
                    tempImageBytes: item.tempImageBytes,
                  );
                }
              }

              _updateTabController();
            });
          },
          existingCategories: categories,
          currentCategoryName: categories[index],
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

    final newMenu = await showDialog<MenuListItem>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AddMenuDialog(
          titleController: titleController,
          descriptionController: descriptionController,
          priceController: priceController,
          category: categories[_tabController.index],
          storeId: 'store-001',
        );
      },
    );

    if (newMenu != null) {
      setState(() {
        menuItems.add(newMenu);
        _updateCategorizedMenu();
      });
      // 컨트롤러 초기화는 AddMenuDialog에서 처리하므로 여기서 불필요
    }
  }

  Future<void> _editMenu(int categoryIndex, int menuIndex) async {
    final category = categories[categoryIndex];
    final menuItem = categorizedMenu[category]![menuIndex]; // menuItem 정의 추가

    final updatedMenu = await showDialog<MenuListItem>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return EditMenuDialog(
          titleController: titleController,
          descriptionController: descriptionController,
          priceController: priceController,
          menuItem: menuItem,
        );
      },
    );

    if (updatedMenu != null) {
      setState(() {
        final menuItemIndex = menuItems.indexWhere(
            (item) => item.id == menuItem.id && item.menuId == menuItem.menuId);
        if (menuItemIndex != -1) {
          menuItems[menuItemIndex] = updatedMenu;
          _updateCategorizedMenu();
        }
      });
      titleController.clear();
      descriptionController.clear();
      priceController.clear();
    }
  }

  void _showDeleteMenuDialog(int categoryIndex, int menuIndex) {
    showDialog(
      context: context,
      barrierDismissible: true, // 바깥 클릭 시 닫힘 적용
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "メニュー削除",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: Color(0xFF263238)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        content:
            const Text("本当にこのメニューを削除しますか？", style: TextStyle(fontSize: 16)),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  final category = categories[categoryIndex];
                  final menuItem = categorizedMenu[category]![menuIndex];
                  final menuItemIndex = menuItems.indexWhere((item) =>
                      item.id == menuItem.id && item.menuId == menuItem.menuId);
                  if (menuItemIndex != -1) {
                    menuItems[menuItemIndex] = MenuListItem(
                      id: menuItem.id,
                      storeId: menuItem.storeId,
                      menuId: menuItem.menuId,
                      category: menuItem.category,
                      title: menuItem.title,
                      description: menuItem.description,
                      price: menuItem.price,
                      imageUrl: menuItem.imageUrl,
                      createdAt: menuItem.createdAt,
                      updatedAt: DateTime.now(),
                      menuStatus: 'disable',
                      tempImageBytes: menuItem.tempImageBytes,
                    );
                    _updateCategorizedMenu();
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メニューが無効化されました。')),
                );
              },
              child: const Text(
                "削除",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 새로운 초기화 메서드
  void _showDeleteALLMenuDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // 바깥 클릭 시 닫힘 적용
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "メニュー全削除",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: Color(0xFF263238)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        content:
            const Text("本当にこのメニューを削除しますか？", style: TextStyle(fontSize: 16)),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  // 모든 menuItems의 menuStatus를 'disable'로 설정
                  for (int i = 0; i < menuItems.length; i++) {
                    menuItems[i] = MenuListItem(
                      id: menuItems[i].id,
                      storeId: menuItems[i].storeId,
                      menuId: menuItems[i].menuId,
                      category: menuItems[i].category,
                      title: menuItems[i].title,
                      description: menuItems[i].description,
                      price: menuItems[i].price,
                      imageUrl: menuItems[i].imageUrl,
                      createdAt: menuItems[i].createdAt,
                      updatedAt: DateTime.now(), // 업데이트 시간을 현재로 설정
                      menuStatus: 'disable',
                      tempImageBytes: menuItems[i].tempImageBytes,
                    );
                  }
                  _updateCategorizedMenu(); // categorizedMenu를 업데이트
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メニューが無効化されました。')),
                );
              },
              child: const Text(
                "削除",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(int index) {
    showDialog(
      context: context,
      barrierDismissible: true, // 바깥 클릭 시 닫힘 적용
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "カテゴリー削除",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: Color(0xFF263238)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
        content: const Text("このカテゴリーを削除しますか？", style: TextStyle(fontSize: 16)),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  final category = categories[index];
                  menuItems.removeWhere((item) => item.category == category);
                  categories.removeAt(index);
                  categorizedMenu.remove(category);
                  _originalMenuData.remove(category);
                  _updateTabController();
                  if (_tabController.index >= categories.length &&
                      categories.isNotEmpty) {
                    _tabController.index = categories.length - 1;
                  }
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('カテゴリーが削除されました。')),
                );
              },
              child: const Text(
                "削除",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return AddCategoryDialog(
          controller: _categoryNameController,
          onAddCategory: (categoryName) {
            setState(() {
              categories.add(categoryName);
              categorizedMenu[categoryName] = [];
              _updateTabController();
              _tabController.index = categories.length - 1;
            });
          },
          existingCategories: categories,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Stack(
          children: [
            Row(
              children: [
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
                              color: Color(0xFF263238)),
                        ),
                      ),
                      if (categories.isNotEmpty)
                        SizedBox(
                          height: 60,
                          child: Listener(
                            onPointerSignal: (PointerSignalEvent event) {
                              if (event is PointerScrollEvent) {
                                final delta = event.scrollDelta.dy;
                                if (_scrollController.hasClients) {
                                  final maxExtent = _scrollController
                                      .position.maxScrollExtent;
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
                                          horizontal: 4, vertical: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF263238)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(32),
                                          border: Border.all(
                                              color: const Color(0xFF263238)),
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
                                              onTap: () =>
                                                  _showEditCategoryDialog(
                                                      index),
                                              child: const Icon(Icons.edit,
                                                  size: 18,
                                                  color: Colors.blueGrey),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () =>
                                                  _showDeleteCategoryDialog(
                                                      index),
                                              child: const Icon(Icons.close,
                                                  size: 18,
                                                  color: Colors.redAccent),
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
                              final menuList = (categorizedMenu[category] ?? [])
                                  .where(
                                      (item) => item.menuStatus == 'available')
                                  .toList();
                              return ListView.builder(
                                padding: const EdgeInsets.all(24),
                                itemCount: menuList.length,
                                itemBuilder: (context, index) {
                                  final menuItem = menuList[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 8),
                                    color: const Color(0xFFFFFFFF),
                                    elevation: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.15),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: menuItem.tempImageBytes != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.memory(
                                                    menuItem.tempImageBytes!,
                                                    fit: BoxFit.cover,
                                                    width: 50,
                                                    height: 50,
                                                  ),
                                                )
                                              : menuItem.imageUrl.isNotEmpty
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        menuItem.imageUrl,
                                                        fit: BoxFit.cover,
                                                        width: 50,
                                                        height: 50,
                                                        errorBuilder: (context,
                                                                error,
                                                                stackTrace) =>
                                                            const Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color: Colors
                                                                    .grey),
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey),
                                        ),
                                        title: Text(menuItem.title),
                                        subtitle: Text(menuItem.description),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('${menuItem.price}円'),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _editMenu(
                                                  _tabController.index, index),
                                              child: const Icon(Icons.edit,
                                                  size: 18,
                                                  color: Colors.blueGrey),
                                            ),
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                              onTap: () =>
                                                  _showDeleteMenuDialog(
                                                      _tabController.index,
                                                      index),
                                              child: const Icon(Icons.close,
                                                  size: 18,
                                                  color: Colors.redAccent),
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
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(width: 1, color: Colors.grey[300]),
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
                              color: Color(0xFF263238)),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: SizedBox(
                            width: 270,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF263238),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _saveChanges,
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
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: _showDeleteALLMenuDialog,
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
            if (_isLoading) const MenuManagementPageLoading(),
          ],
        ),
      ),
    );
  }
}
