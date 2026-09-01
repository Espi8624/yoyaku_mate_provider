import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../../../models/store_settings.dart';
import '../../dialogs/number_input_dialog.dart';
import '../../dialogs/menu_selection_settings_dialog.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';

String _describeError(Object error) {
  if (error is ApiException) return error.message;
  return '予期しないエラーが発生しました: $error';
}

class WaitingSettingsSection extends ConsumerWidget {
  final bool isReadOnly;

  const WaitingSettingsSection({
    super.key,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(selectedStoreProfileProvider)?.id;
    if (storeId == null) return const SizedBox();

    final storeSettings =
        ref.watch(storeSettingsProvider(storeId: storeId)).valueOrNull;

    if (storeSettings == null) {
      return const SizedBox();
    }

    return ProfileSection(
      title: '待機リスト政策',
      children: [
        ProfileSettingItem(
          title: '待機登録時メニュー選択有効化',
          subtitle:
              storeSettings.waitingPolicy.enableMenuSelection ? 'On' : 'Off',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showMenuSelectionSettingsDialog(
                  context, ref, storeSettings),
        ),
        ProfileSettingItem(
          title: '最大受付可能人数',
          subtitle: '${storeSettings.waitingPolicy.maxWaitingCount}人',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showNumberInputDialog(
                    context,
                    ref,
                    title: '最大受付可能人数設定',
                    initialValue: storeSettings.waitingPolicy.maxWaitingCount,
                    onConfirm: (value) async {
                      final updatedPolicy = storeSettings.waitingPolicy
                          .copyWith(maxWaitingCount: value);
                      await ref
                          .read(storeActionsProvider.notifier)
                          .updateStoreSettings(
                            storeSettings.copyWith(
                                waitingPolicy: updatedPolicy),
                          );
                    },
                  ),
        ),
      ],
    );
  }

  Future<void> _showMenuSelectionSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    StoreSettings storeSettings,
  ) async {
    final result = await showDialog<MenuSelectionSettingsResult>(
      context: context,
      builder: (_) => MenuSelectionSettingsDialog(
        initialEnableMenuSelection:
            storeSettings.waitingPolicy.enableMenuSelection,
        initialRequireOneMenuPerPerson:
            storeSettings.waitingPolicy.requireOneMenuPerPerson,
      ),
    );

    if (result != null) {
      final updatedPolicy = storeSettings.waitingPolicy.copyWith(
        enableMenuSelection: result.enableMenuSelection,
        requireOneMenuPerPerson: result.requireOneMenuPerPerson,
      );
      try {
        await ref.read(storeActionsProvider.notifier).updateStoreSettings(
              storeSettings.copyWith(waitingPolicy: updatedPolicy),
            );
        if (context.mounted) {
          ToastWidget.show(context, 'メニュー選択設定を更新しました', type: ToastType.info);
        }
      } catch (e) {
        if (context.mounted) {
          ToastWidget.show(context, _describeError(e), type: ToastType.error);
        }
      }
    }
  }

  Future<void> _showNumberInputDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required int initialValue,
    required Future<void> Function(int) onConfirm,
  }) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => NumberInputDialog(
          title: title, labelText: '人数', initialValue: initialValue),
    );
    if (result != null) {
      try {
        await onConfirm(result);
        if (context.mounted) {
          ToastWidget.show(context, '$titleが$result人に設定されました。',
              type: ToastType.info);
        }
      } catch (e) {
        if (context.mounted) {
          ToastWidget.show(context, _describeError(e), type: ToastType.error);
        }
      }
    }
  }
}
