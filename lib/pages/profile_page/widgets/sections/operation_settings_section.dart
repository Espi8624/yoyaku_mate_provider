import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../models/menu_list.dart';
import '../../../../models/store_settings.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/confirmation_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';
import '../../../menu_management_page/menu_management_providers.dart';
import '../../dialogs/business_hours_dialog.dart';
import '../../dialogs/holiday_dialog.dart';
import '../../dialogs/language_settings_dialog.dart';
import '../../dialogs/number_input_dialog.dart';
// 必要人員設定/AIアシスタント追加情報の一時非表示に伴い未使用(TODO: 復旧時はコメント解除)
// import '../../dialogs/staff_count_dialog.dart';
// import '../../dialogs/text_input_dialog.dart';
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

    // メニュー表示トグルの活性/非活性判定用。メニューが1件も登録されていない店舗は
    // 表示すべき内容自体が無いため、トグルを操作不能にして常にOFFのまま固定する
    final menuItems = ref
        .watch(menuItemsNotifierProvider(storeId: storeId))
        .valueOrNull
        ?.items;
    final hasMenu = menuItems != null && menuItems.isNotEmpty;

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
        // 必要人員設定は一時的に非表示中(TODO: 復旧時はコメント解除)
        // const Divider(height: 1, indent: 16, endIndent: 16),
        // ProfileSettingItem(
        //   title: '必要人員設定',
        //   subtitle: _buildStaffCountSummary(storeSettings.requiredStaffCount),
        //   showTrailingIcon: !isReadOnly,
        //   onTap: isReadOnly
        //       ? null
        //       : () => _showStaffCountDialog(context, ref, storeSettings),
        // ),
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
          title: 'メニュー表示',
          subtitle: hasMenu
              ? '待機画面でメニューを閲覧できるようにする'
              : '登録されたメニューがありません',
          showTrailingIcon: false,
          trailing: Switch(
            value: hasMenu && storeSettings.waitingPolicy.showMenu,
            activeThumbColor: AppColors.accentPrimary,
            onChanged: (isReadOnly || !hasMenu)
                ? null
                : (value) => _updateShowMenu(context, ref, storeSettings, value),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
        ProfileSettingItem(
          title: '多言語対応',
          subtitle: _buildLanguageSummary(storeSettings.supportedLanguages),
          showTrailingIcon: !isReadOnly,
          onTap: isReadOnly
              ? null
              : () => _showLanguageSettingsDialog(
                  context, ref, storeId, storeSettings),
        ),
        // AIアシスタントへの追加情報は一時的に非表示中(TODO: 復旧時はコメント解除)
        // const Divider(height: 1, indent: 16, endIndent: 16),
        // ProfileSettingItem(
        //   title: 'AIアシスタントへの追加情報',
        //   subtitle: storeSettings.aiAdditionalInfo.isNotEmpty
        //       ? storeSettings.aiAdditionalInfo
        //       : 'なし',
        //   showTrailingIcon: !isReadOnly,
        //   onTap: isReadOnly
        //       ? null
        //       : () => _showAIAdditionalInfoDialog(context, ref, storeSettings),
        // ),
      ],
    );
  }

  // 多言語対応設定の要約表示。全言語が対等な選択制のため、件数のみ表示する
  String _buildLanguageSummary(List<String> supportedLanguages) {
    if (supportedLanguages.isEmpty) return '未設定';
    return '${supportedLanguages.length}言語対応中';
  }

  String _buildBusinessHoursSummary(Map<String, Map<String, String>> hours) {
    final weekdayHours =
        '${hours['monday']?['start'] ?? ''}-${hours['monday']?['end'] ?? ''}';
    return '平日: $weekdayHours';
  }

  // 必要人員設定は一時的に非表示中のため未使用(TODO: 復旧時はコメント解除)
  // String _buildStaffCountSummary(Map<String, DayStaffRequirement> requirements) {
  //   // shiftChangeCount(交代回数)は0も有効な設定値(=1ブロック)のため、
  //   // 「設定済みかどうか」の判定にはcount(必要人数)のみを用いる
  //   final hasAnySetting = requirements.values.any((r) => r.count > 0);
  //   if (!hasAnySetting) return '未設定';
  //
  //   final monday = requirements['monday'];
  //   return '月 ${monday?.count ?? 0}名・交代${monday?.shiftChangeCount ?? 0}回 他';
  // }

  Future<void> _updateShowMenu(BuildContext context, WidgetRef ref,
      StoreSettings storeSettings, bool value) async {
    final updatedPolicy =
        storeSettings.waitingPolicy.copyWith(showMenu: value);
    await _applyUpdate(
      context,
      ref,
      storeSettings.copyWith(waitingPolicy: updatedPolicy),
      successMessage: value ? 'メニュー表示をONにしました' : 'メニュー表示をOFFにしました',
    );
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

  // 必要人員設定は一時的に非表示中のため未使用(TODO: 復旧時はコメント解除)
  // Future<void> _showStaffCountDialog(
  //     BuildContext context, WidgetRef ref, StoreSettings storeSettings) async {
  //   final result = await showDialog<Map<String, DayStaffRequirement>>(
  //     context: context,
  //     builder: (_) => StaffCountDialog(
  //       initialRequirements: storeSettings.requiredStaffCount,
  //       closedWeekdayLabels: storeSettings.closedDays.regularWeekly,
  //     ),
  //   );
  //
  //   if (result != null) {
  //     final updatedSettings = storeSettings.copyWith(requiredStaffCount: result);
  //     await _applyUpdate(context, ref, updatedSettings);
  //   }
  // }

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

  // 多言語対応設定ダイアログを開き、保存後に新たに有効化された言語があれば
  // 既存メニューの一括翻訳(バックフィル)を任意で提案する
  Future<void> _showLanguageSettingsDialog(BuildContext context, WidgetRef ref,
      String storeId, StoreSettings storeSettings) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => LanguageSettingsDialog(
          initialSupportedLanguages: storeSettings.supportedLanguages),
    );
    if (result == null) return;

    // 全言語(日本語含む)が対等に選択制なので、今回新たに有効化された言語を
    // そのまま抽出する。日本語・英語・韓国語であっても、一度OFFにしてから
    // 再度ONにした場合はここに含まれうる。
    // 既存メニューはこの言語の翻訳データを持っていないため、後続でバックフィルを提案する
    final oldLanguages = storeSettings.supportedLanguages.toSet();
    final newlyAdded =
        result.where((lang) => !oldLanguages.contains(lang)).toList();

    final updatedSettings = storeSettings.copyWith(supportedLanguages: result);
    await _applyUpdate(context, ref, updatedSettings,
        successMessage: '多言語対応設定を保存しました');

    if (newlyAdded.isEmpty || !context.mounted) return;

    // - valueOrNullだと、この設定画面に来る前にメニュー管理画面を一度も開いて
    //   いない場合(autoDisposeでまだロードされていない)nullになり、確認自体が
    //   出ないまま処理が終わってしまう。.futureで確実に一度読み込む
    List<MenuListItem> menuItems;
    try {
      menuItems = (await ref
              .read(menuItemsNotifierProvider(storeId: storeId).future))
          .items;
    } catch (_) {
      return;
    }
    if (menuItems.isEmpty || !context.mounted) return;

    final confirmed = await showConfirmationDialog(
      context: context,
      title: '既存メニューの翻訳',
      content: '追加した言語について、登録済みのメニュー${menuItems.length}件を今すぐ翻訳しますか？\n'
          '(翻訳APIの呼び出しが発生します。後から個別にメニューを編集して反映することもできます)',
      confirmText: '翻訳する',
      isDestructive: false,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(menuItemsNotifierProvider(storeId: storeId).notifier)
          .backfillTranslations(storeId, newlyAdded);
      if (!context.mounted) return;
      ToastWidget.show(context, '既存メニューの翻訳が完了しました', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      ToastWidget.show(context, _describeError(e), type: ToastType.error);
    }
  }

  // AIアシスタントへの追加情報は一時的に非表示中のため未使用(TODO: 復旧時はコメント解除)
  // Future<void> _showAIAdditionalInfoDialog(
  //     BuildContext context, WidgetRef ref, StoreSettings storeSettings) async {
  //   final result = await showDialog<String>(
  //     context: context,
  //     builder: (_) => TextInputDialog(
  //       title: 'AIアシスタントへの追加情報',
  //       labelText: '追加情報',
  //       helperText: '周辺のランドマークや、AIに知っておいてほしい特定の情報を入力してください。',
  //       initialValue: storeSettings.aiAdditionalInfo,
  //     ),
  //   );
  //
  //   if (result != null) {
  //     final updatedSettings = storeSettings.copyWith(aiAdditionalInfo: result);
  //     await _applyUpdate(context, ref, updatedSettings);
  //   }
  // }
}
