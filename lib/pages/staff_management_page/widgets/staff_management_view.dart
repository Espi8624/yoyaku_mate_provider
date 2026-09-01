import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/staff_management_page/staff_management_providers.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/models/user_profile.dart';
import 'package:yoyaku_mate_provider/models/store_settings.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/constants/staff_status.dart';
import 'package:yoyaku_mate_provider/constants/time_block.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/dialogs/day_availability_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

// 例外からユーザー向けメッセージを組み立てる共通処理
// (ApiExceptionはメッセージ部分のみ、それ以外は予期しないエラーとして表示)
String _describeError(Object error, {required String actionLabel}) {
  if (error is ApiException) {
    return '$actionLabel: ${error.message}';
  }
  return '予期しないエラーが発生しました: $error';
}

class StaffManagementView extends ConsumerWidget {
  final String storeId;

  const StaffManagementView({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // API取得結果は宣言的に購読するだけでよく、initState等での明示的な呼び出しは不要
    final staffAsync = ref.watch(staffListProvider(storeId: storeId));
    final currentUser = ref.watch(userProfileProvider).valueOrNull;
    final storeSettings =
        ref.watch(storeSettingsProvider(storeId: storeId)).valueOrNull;
    final bool isManager = currentUser?.role == 'manager';

    final staffList = staffAsync.value ?? const <Map<String, dynamic>>[];

    // マネージャーは store_staff_info に自分の項目を持たないため、
    // スタッフ一覧の中から「本人の項目」と「それ以外のメンバー」を分離する
    Map<String, dynamic>? myStaffEntry;
    final List<Map<String, dynamic>> otherStaffList = [];
    for (final entry in staffList) {
      if (!isManager && entry['user_id'] == currentUser?.id) {
        myStaffEntry = entry;
      } else {
        otherStaffList.add(entry);
      }
    }

    Widget listBody;
    if (staffAsync.hasError && !staffAsync.hasValue) {
      listBody = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('エラーが発生しました: ${staffAsync.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(staffListProvider(storeId: storeId)),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    } else if (staffAsync.hasValue && otherStaffList.isEmpty) {
      listBody = const Center(
          child: Text(
        '現在登録されている他のメンバーはいません。',
        style: TextStyle(fontSize: 16, color: AppColors.textTertiary),
      ));
    } else {
      listBody = ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: otherStaffList.length,
        itemBuilder: (context, index) {
          final staff = otherStaffList[index];

          return _StaffCard(
            staff: staff,
            storeId: storeId,
            storeSettings: storeSettings,
            // マネージャーは全メンバーを操作可能。
            // スタッフは自分以外のカードを一切操作できない(閲覧のみ)
            canManageStatusAndPermissions: isManager,
            canEditAvailability: isManager,
          );
        },
      );
    }

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 最上段: 自分自身の情報カード
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: isManager
                  ? _MyManagerCard(userProfile: currentUser)
                  : (myStaffEntry != null
                      ? _StaffCard(
                          staff: myStaffEntry,
                          storeId: storeId,
                          storeSettings: storeSettings,
                          // 自分自身のステータス承認・権限付与はUI上でも許可しない。
                          // 勤務可能時間の編集のみ自分のカードから行える
                          canManageStatusAndPermissions: false,
                          canEditAvailability: true,
                        )
                      : const SizedBox.shrink()),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                  height: 1, thickness: 0.5, color: AppColors.border),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 4),
              child: Text(
                'メンバー一覧',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: listBody,
              ),
            ),
          ],
        ),

        // 初回ロード中(=まだ一度もデータを取得できていない間)のみ全画面スピナーを表示。
        // invalidateによる再取得中は直前のデータを表示したまま裏で更新する
        // (ちらつきを避けるため、更新中の細かいインジケーターは付けない)
        if (staffAsync.isLoading && !staffAsync.hasValue)
          const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary)),
      ],
    );
  }
}

// マネージャー自身の情報を表示する軽量カード
// (マネージャーは store_staff_info のエンティティではないため、
//  承認/拒否・権限・勤務可能時間の概念自体を持たず、操作UIも存在しない)
class _MyManagerCard extends StatelessWidget {
  final UserProfile? userProfile;

  const _MyManagerCard({required this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.accentPrimary, width: 1),
      ),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile?.name ?? '...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userProfile?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.roleManager,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '管理者',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ephemeral State (展開/折りたたみ) は useState で保持し、StatefulWidgetを廃止
class _StaffCard extends HookConsumerWidget {
  final Map<String, dynamic> staff;
  final String storeId;
  // 承認/拒否・権限スイッチ(他人に対する操作)を表示するかどうか
  final bool canManageStatusAndPermissions;
  // 勤務可能時間の編集を表示するかどうか
  final bool canEditAvailability;
  // 店舗の営業時間設定(nullの場合は営業時間による制限をかけない)
  final StoreSettings? storeSettings;

  const _StaffCard({
    required this.staff,
    required this.storeId,
    required this.canManageStatusAndPermissions,
    required this.canEditAvailability,
    this.storeSettings,
  });

  // ステータス変更ボタン共通処理 (承認/拒否/承認取り消し/再承認)
  Future<void> _changeStatus(
      BuildContext context, WidgetRef ref, String status) async {
    try {
      await ref
          .read(staffActionsProvider.notifier)
          .updateStatus(storeId, staff['_id'], status);
      if (!context.mounted) return;
      final message =
          status == StaffStatus.approved ? 'スタッフを承認しました' : 'スタッフを拒否しました';
      ToastWidget.show(context, message, type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      ToastWidget.show(
        context,
        _describeError(e, actionLabel: 'ステータス更新失敗'),
        type: ToastType.error,
      );
    }
  }

  // 曜日バッジタップ時、その曜日1日分だけの勤務可能時間帯を編集するダイアログを表示
  Future<void> _showDayAvailabilityDialog(
      BuildContext context, WidgetRef ref, String day, String dayLabel) async {
    final availability = staff['availability'] as Map<String, dynamic>? ?? {};
    final currentBlocks =
        (availability[day] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            <String>[];

    final hours = storeSettings?.operatingHours[day];

    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => DayAvailabilityDialog(
        dayLabel: dayLabel,
        initialBlocks: currentBlocks,
        is24Hours: storeSettings?.is24Hours ?? false,
        isClosed: storeSettings?.closedDays.isClosedOn(dayLabel) ?? false,
        businessStart: hours?['start'],
        businessEnd: hours?['end'],
      ),
    );

    if (result == null) return;

    // 他の曜日の値は維持したまま、タップされた曜日だけを更新してサーバーに送信
    final updatedAvailability = {
      for (final d in Weekday.values)
        d: (availability[d] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
    };
    updatedAvailability[day] = result;

    try {
      await ref
          .read(staffActionsProvider.notifier)
          .updateAvailability(storeId, staff['_id'], updatedAvailability);
      if (!context.mounted) return;
      ToastWidget.show(context, '勤務可能時間を更新しました', type: ToastType.success);
    } catch (e) {
      if (!context.mounted) return;
      ToastWidget.show(
        context,
        _describeError(e, actionLabel: '勤務可能時間の更新失敗'),
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final isAvailabilityExpanded = useState(false);
    final status = staff['status'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff['user_name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff['email'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                _buildStatusDot(status),
              ],
            ),

            // 承認済み、かつステータス/権限の操作が許可されている場合のみ「権限設定」を表示
            if (status == StaffStatus.approved &&
                canManageStatusAndPermissions) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => isExpanded.value = !isExpanded.value,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "権限設定",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      isExpanded.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              if (isExpanded.value) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  children: [
                    const Text(
                      'メニュー編集権限:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: (staff['permissions'] as List<dynamic>?)
                              ?.contains('menu_edit') ??
                          false,
                      onChanged: (value) async {
                        final currentPermissions =
                            (staff['permissions'] as List<dynamic>?)
                                    ?.map((e) => e.toString())
                                    .toList() ??
                                [];
                        if (value) {
                          currentPermissions.add('menu_edit');
                        } else {
                          currentPermissions.remove('menu_edit');
                        }
                        try {
                          await ref
                              .read(staffActionsProvider.notifier)
                              .updatePermissions(
                                  storeId, staff['_id'], currentPermissions);
                          if (!context.mounted) return;
                          ToastWidget.show(context, '権限を更新しました',
                              type: ToastType.success);
                        } catch (e) {
                          if (!context.mounted) return;
                          ToastWidget.show(
                            context,
                            _describeError(e, actionLabel: '権限更新失敗'),
                            type: ToastType.error,
                          );
                        }
                      },
                      activeColor: AppColors.accentPrimary,
                    ),
                  ],
                ),
              ],
            ],

            // 承認済み、かつ勤務可能時間の編集が許可されている場合のみ「勤務可能日」を表示
            // (「権限設定」とは独立して開閉可能)
            if (status == StaffStatus.approved && canEditAvailability) ...[
              const SizedBox(height: 12),
              const Divider(),
              GestureDetector(
                onTap: () => isAvailabilityExpanded.value =
                    !isAvailabilityExpanded.value,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      "勤務可能日",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      isAvailabilityExpanded.value
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              if (isAvailabilityExpanded.value) ...[
                const SizedBox(height: 12),
                const Text(
                  '曜日をタップして編集',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _AvailabilitySummary(
                  availability:
                      staff['availability'] as Map<String, dynamic>? ?? {},
                  onDayTap: (day, dayLabel) =>
                      _showDayAvailabilityDialog(context, ref, day, dayLabel),
                ),
              ],
            ],

            // ステータス変更ボタンは操作許可がある場合のみ表示
            if (canManageStatusAndPermissions) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 承認済みの場合: 拒否ボタンを表示 (承認取り消し)
                  if (status == StaffStatus.approved)
                    ElevatedButton(
                      onPressed: () =>
                          _changeStatus(context, ref, StaffStatus.rejected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rejected,
                        foregroundColor: AppColors.textPrimaryLight,
                      ),
                      child: const Text('承認取り消し'),
                    ),

                  // 承認待ちの場合: 拒否と承認ボタンを表示
                  if (status == StaffStatus.pending) ...[
                    OutlinedButton(
                      onPressed: () =>
                          _changeStatus(context, ref, StaffStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('拒否'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () =>
                          _changeStatus(context, ref, StaffStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('承認'),
                    ),
                  ],

                  // 拒否済みの場合: 承認ボタンを表示 (再承認)
                  if (status == StaffStatus.rejected)
                    ElevatedButton(
                      onPressed: () =>
                          _changeStatus(context, ref, StaffStatus.approved),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('再承認'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(String status) {
    Color color;
    String tooltip;

    switch (status) {
      case StaffStatus.approved:
        color = AppColors.approved;
        tooltip = '承認済み';
        break;
      case StaffStatus.pending:
        color = AppColors.notSubmitted;
        tooltip = '承認待ち';
        break;
      case StaffStatus.rejected:
        color = AppColors.notSubmitted;
        tooltip = '拒否済み';
        break;
      default:
        color = AppColors.notSubmitted;
        tooltip = status;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// スタッフの勤務可能日を曜日バッジ(ボタン)で要約表示するウィジェット
// 選択された時間帯が1つでもある曜日は「可能」、無ければ「不可」として表示
// 各バッジをタップすると、その曜日の勤務可能時間帯を編集できる
class _AvailabilitySummary extends StatelessWidget {
  final Map<String, dynamic> availability;
  final void Function(String day, String dayLabel) onDayTap;

  const _AvailabilitySummary({
    required this.availability,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(Weekday.values.length, (index) {
        final day = Weekday.values[index];
        final dayLabel = Weekday.labels[index];
        final blocks = availability[day] as List<dynamic>?;
        final isAvailable = blocks != null && blocks.isNotEmpty;

        return InkWell(
          onTap: () => onDayTap(day, dayLabel),
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.accentPrimary : Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(
                color: isAvailable ? AppColors.accentPrimary : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Text(
              dayLabel,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAvailable ? AppColors.textPrimaryLight : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }
}
