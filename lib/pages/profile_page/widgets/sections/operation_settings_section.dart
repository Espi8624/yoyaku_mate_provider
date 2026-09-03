import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../models/store_settings.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../dialogs/business_hours_dialog.dart';
import '../../dialogs/holiday_dialog.dart';
import '../../dialogs/number_input_dialog.dart';
import '../../dialogs/staff_count_dialog.dart';
import '../../dialogs/text_input_dialog.dart';
import '../profile_section.dart';
import '../profile_setting_item.dart';

// 更新の成功/失敗は共有状態ではなく、呼び出し直後にtry/catchで即時Toast表示する
String _describeError(Object error) {
  if (error is ApiException) return error.message;
  return '予期しないエラーが発生しました: $error';
}

class OperationSettingsSection extends ConsumerWidget {
  final bool isReadOnly;

  const OperationSettingsSection({
    super.key,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(selectedStoreProfileProvider)?.id;
    if (storeId == null) return const SizedBox();

    final storeSettingsAsync = ref.watch(storeSettingsProvider(storeId: storeId));
    final storeSettings = storeSettingsAsync.valueOrNull;

    if (storeSettings == null) return const SizedBox();

    return ProfileSection(
      title: '運営設定',
      children: [
        ProfileSettingItem(
          title: 'チームあたりの予想待機時間',
          subtitle: '${storeSettings.waitingPolicy.estimatedWaitTime ?? 10}分',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showEditWaitTimeDialog(context, ref, storeSettings),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ProfileSettingItem(
          title: '営業時間',
          subtitle: storeSettings.is24Hours
              ? '24時間営業 (リセット: ${storeSettings.resetTime})'
              : _buildBusinessHoursSummary(storeSettings.operatingHours),
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showBusinessHoursDialog(context, ref, storeSettings),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ProfileSettingItem(
          title: '必要人員設定',
          subtitle: _buildStaffCountSummary(storeSettings.requiredStaffCount),
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showStaffCountDialog(context, ref, storeSettings),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ProfileSettingItem(
          title: '休業日',
          subtitle: storeSettings.closedDays.summary,
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showHolidayDialog(context, ref, storeSettings),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ProfileSettingItem(
          title: 'AIアシスタントへの追加情報',
          subtitle: storeSettings.aiAdditionalInfo.isNotEmpty
              ? storeSettings.aiAdditionalInfo
              : 'なし',
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showAIAdditionalInfoDialog(context, ref, storeSettings),
        ),
      ],
    );
  }

  String _buildBusinessHoursSummary(Map<String, Map<String, String>> hours) {
    final weekdayHours =
        '${hours['monday']?['start'] ?? ''}-${hours['monday']?['end'] ?? ''}';
    return '平日: $weekdayHours';
  }

  // 必要人員設定の要約表示。1件も設定されていない場合は「未設定」を表示し、
  // それ以外は月曜日の値を代表例として表示する(営業時間の要約と同じ方針)
  String _buildStaffCountSummary(Map<String, DayStaffRequirement> requirements) {
    // shiftChangeCount(交代回数)は0も有効な設定値(=1ブロック)のため、
    // 「設定済みかどうか」の判定にはcount(必要人数)のみを用いる
    final hasAnySetting = requirements.values.any((r) => r.count > 0);
    if (!hasAnySetting) return '未設定';

    final monday = requirements['monday'];
    return '月 ${monday?.count ?? 0}名・交代${monday?.shiftChangeCount ?? 0}回 他';
  }

  Future<void> _applyUpdate(
      BuildContext context, WidgetRef ref, StoreSettings updated,
      {String? successMessage}) async {
    try {
      await ref.read(storeActionsProvider.notifier).updateStoreSettings(updated);
      if (!context.mounted) return;
      ToastWidget.show(context, successMessage ?? '設定が保存されました',
          type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      ToastWidget.show(context, _describeError(e), type: ToastType.error);
    }
  }

  Future<void> _showEditWaitTimeDialog(
      BuildContext context, WidgetRef ref, StoreSettings storeSettings) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => NumberInputDialog(
          title: '予想待機時間設定',
          labelText: '分 (1チームあたり)',
          initialValue: storeSettings.waitingPolicy.estimatedWaitTime ?? 10),
    );

    if (result != null) {
      final updatedPolicy =
          storeSettings.waitingPolicy.copyWith(estimatedWaitTime: result);
      final updatedSettings =
          storeSettings.copyWith(waitingPolicy: updatedPolicy);
      await _applyUpdate(context, ref, updatedSettings,
          successMessage: '予想待機時間が$result分に設定されました。');
    }
  }

  Future<void> _showBusinessHoursDialog(
      BuildContext context, WidgetRef ref, StoreSettings storeSettings) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => BusinessHoursDialog(
        initialHours: storeSettings.operatingHours,
        initialIs24Hours: storeSettings.is24Hours,
        initialResetTime: storeSettings.resetTime,
        closedWeekdayLabels: storeSettings.closedDays.regularWeekly,
      ),
    );

    if (result != null) {
      final updatedSettings = storeSettings.copyWith(
        operatingHours:
            result['operatingHours'] as Map<String, Map<String, String>>,
        is24Hours: result['is24Hours'] as bool,
        resetTime: result['resetTime'] as String,
      );
      await _applyUpdate(context, ref, updatedSettings);
    }
  }

  Future<void> _showStaffCountDialog(
      BuildContext context, WidgetRef ref, StoreSettings storeSettings) async {
    final result = await showDialog<Map<String, DayStaffRequirement>>(
      context: context,
      builder: (_) => StaffCountDialog(
        initialRequirements: storeSettings.requiredStaffCount,
        closedWeekdayLabels: storeSettings.closedDays.regularWeekly,
      ),
    );

    if (result != null) {
      final updatedSettings = storeSettings.copyWith(requiredStaffCount: result);
      await _applyUpdate(context, ref, updatedSettings);
    }
  }

  Future<void> _showHolidayDialog(
      BuildContext context, WidgetRef ref, StoreSettings storeSettings) async {
    final result = await showDialog<ClosedDays>(
      context: context,
      builder: (_) =>
          HolidayDialog(initialClosedDays: storeSettings.closedDays),
    );

    if (result != null) {
      final updatedSettings = storeSettings.copyWith(closedDays: result);
      await _applyUpdate(context, ref, updatedSettings);
    }
  }

  Future<void> _showAIAdditionalInfoDialog(
      BuildContext context, WidgetRef ref, StoreSettings storeSettings) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => TextInputDialog(
        title: 'AIアシスタントへの追加情報',
        labelText: '追加情報',
        helperText: '周辺のランドマークや、AIに知っておいてほしい特定の情報を入力してください。',
        initialValue: storeSettings.aiAdditionalInfo,
      ),
    );

    if (result != null) {
      final updatedSettings = storeSettings.copyWith(aiAdditionalInfo: result);
      await _applyUpdate(context, ref, updatedSettings);
    }
  }
}
