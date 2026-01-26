import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/menu_list.dart';
import '../../../../models/waiting_list.dart'; // Import for MenuItem
import '../../../../services/menu_service.dart';
import '../../../../widgets/common_dialogs/base_dialog.dart';
import '../../../../widgets/common_widgets/toast_widget.dart';

class AddWaitingDialog extends StatefulWidget {
  final String storeId;
  final bool enableMenuSelection;
  final bool requireOneMenuPerPerson;

  const AddWaitingDialog({
    super.key,
    required this.storeId,
    bool? enableMenuSelection,
    bool? requireOneMenuPerPerson,
  })  : enableMenuSelection = enableMenuSelection ?? false,
        requireOneMenuPerPerson = requireOneMenuPerPerson ?? false;

  @override
  State<AddWaitingDialog> createState() => _AddWaitingDialogState();
}

class _AddWaitingDialogState extends State<AddWaitingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _partySizeController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();

  // Menu Selection
  bool _isLoadingMenus = false;
  List<MenuListItem> _availableMenus = [];
  final Map<String, int> _selectedMenuCounts = {}; // menuId -> count

  @override
  void initState() {
    super.initState();
    if (widget.enableMenuSelection) {
      _fetchMenus();
    }
  }

  Future<void> _fetchMenus() async {
    setState(() => _isLoadingMenus = true);
    try {
      final menuService = MenuService();
      final menus = await menuService.fetchMenuItems(widget.storeId);
      if (mounted) {
        setState(() {
          // Only show enabled menus and those marked for pre-order
          _availableMenus = menus
              .where((m) =>
                  m.menuStatus == 'available' &&
                  (m.isPreOrderAvailable)) // Assuming default false, only show explicit true
              .toList();
          _isLoadingMenus = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch menus: $e');
      if (mounted) {
        setState(() => _isLoadingMenus = false);
      }
    }
  }

  @override
  void dispose() {
    _partySizeController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Build selected menu items list
      final List<MenuItem> selectedMenuItems = [];
      int totalQuantity = 0;
      _selectedMenuCounts.forEach((menuId, count) {
        if (count > 0) {
          final menu = _availableMenus.firstWhere((m) => m.menuId == menuId);
          selectedMenuItems.add(MenuItem(
            menuId: menu.menuId,
            name: menu.title,
            quantity: count,
            // options: ... (could be added later if needed)
          ));
          totalQuantity += count;
        }
      });

      final partySize = int.parse(_partySizeController.text);

      // Validation: One Menu Per Person
      if (widget.requireOneMenuPerPerson && totalQuantity < partySize) {
        ToastWidget.show(context, '1人1メニュー制限: 人数分以上のメニューを選択してください',
            type: ToastType.error);
        return;
      }

      final newItemData = {
        'partySize': partySize,
        'contact': _contactController.text.trim().isEmpty
            ? ''
            : _contactController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? ''
            : _notesController.text.trim(),
        'menuItems': selectedMenuItems,
      };
      Navigator.of(context).pop(newItemData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: '新しい待機追加',
      content: SizedBox(
        width: widget.enableMenuSelection
            ? 500
            : null, // Wider if menu selection enabled
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _partySizeController,
                decoration: const InputDecoration(
                    labelText: '人数', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return '人数を入力してください';
                  if (int.tryParse(v) == null) return '有効な数字を入力してください';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                    labelText: '連絡先', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: '要望事項', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              if (widget.enableMenuSelection) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  "メニュー事前注文",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_isLoadingMenus)
                  const Center(child: CircularProgressIndicator())
                else if (_availableMenus.isEmpty)
                  const Text("注文可能なメニューがありません")
                else
                  Container(
                    height: 250, // Limit height and scroll
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: _availableMenus.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final menu = _availableMenus[index];
                        final count = _selectedMenuCounts[menu.menuId] ?? 0;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.only(left: 8, right: 0),
                          horizontalTitleGap: 12,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: menu.tempImageBytes != null
                                  ? Image.memory(menu.tempImageBytes!,
                                      fit: BoxFit.cover)
                                  : menu.menuImageUrl.isNotEmpty
                                      ? Image.network(menu.menuImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                                  stackTrace) =>
                                              const Icon(
                                                  Icons.image_not_supported,
                                                  color:
                                                      AppColors.textSecondary))
                                      : const Icon(Icons.image_not_supported,
                                          color: AppColors.textSecondary),
                            ),
                          ),
                          title: Text(menu.title),
                          subtitle: Text('¥${menu.price}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: count > 0
                                    ? () => setState(() {
                                          _selectedMenuCounts[menu.menuId] =
                                              count - 1;
                                        })
                                    : null,
                              ),
                              Text('$count',
                                  style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(() {
                                  _selectedMenuCounts[menu.menuId] = count + 1;
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: AppColors.cardBackground,
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: _submitForm,
                  child: const Text("追加"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
