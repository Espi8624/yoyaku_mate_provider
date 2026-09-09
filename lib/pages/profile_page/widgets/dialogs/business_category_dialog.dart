import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';
import '../../../../models/store_category.dart';
import '../../../../widgets/common_dialogs/base_dialog.dart';

/// 業種編集ダイアログ。選択した [StoreCategory] のワイヤー値(business_category)を返す。
class BusinessCategoryDialog extends StatelessWidget {
  final StoreCategory? initialCategory;

  const BusinessCategoryDialog({super.key, required this.initialCategory});

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      title: '業種',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: StoreCategory.values.map((category) {
          final isSelected = category == initialCategory;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(category.label),
            trailing: isSelected
                ? const Icon(Icons.check_circle,
                    color: AppColors.accentPrimary)
                : const Icon(Icons.circle_outlined, color: AppColors.border),
            onTap: () => Navigator.of(context).pop(category.value),
          );
        }).toList(),
      ),
    );
  }
}
