import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/constants/time_block.dart';
import 'package:yoyaku_mate_provider/models/shift_change_request.dart';
import 'package:yoyaku_mate_provider/models/shift_table.dart';
import 'package:yoyaku_mate_provider/models/store_settings.dart';
import 'package:yoyaku_mate_provider/pages/staff_management_page/shift_table_providers.dart';
import 'package:yoyaku_mate_provider/pages/staff_management_page/staff_management_providers.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';
import 'package:yoyaku_mate_provider/services/api_exception.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/toast_widget.dart';

// --- 日付/時間ユーティリティ ---

// 指定日を含む週の月曜日 (時刻情報は切り捨て)
DateTime _mondayOf(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

String _formatWeekStartDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

int? _minutesOf(String? time) {
  if (time == null) return null;
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

// 分(0〜1439)を "HH:MM" 形式に変換
// (重複シフトをまとめたカードの時間帯表示、シフト編集ダイアログの「直」選択肢に使う)
String _formatMinutesLabel(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

// 曜日キーから表示ラベル("monday" → "月")を取得
String _dayLabel(String day) {
  final index = Weekday.values.indexOf(day);
  return index >= 0 ? Weekday.labels[index] : day;
}

// 曜日+開始/終了時刻から、対応する「直」ラベル("2直")を求める。営業時間設定が
// 変わった等で一致する直が無い場合は、時刻そのものをフォールバック表示する
// (修正依頼の From/To 表示用)
String _slotLabelFor(
    String day, String startTime, String endTime, StoreSettings? settings) {
  final slots = _computeShiftSlots(day, settings);
  for (final slot in slots) {
    if (slot.startTime == startTime && slot.endTime == endTime) {
      return '${slot.index + 1}直';
    }
  }
  return '$startTime-$endTime';
}

// 営業時間設定・既存シフトから、グリッドに表示する時間範囲(時単位)を算出
// 情報が無い場合は 9時〜21時をデフォルトとする
({int startHour, int endHour}) _computeHourRange(
    StoreSettings? settings, List<Shift> shifts) {
  if (settings?.is24Hours ?? false) {
    return (startHour: 0, endHour: 24);
  }

  int? minStartMinutes;
  int? maxEndMinutes;

  if (settings != null) {
    for (final day in Weekday.values) {
      final hours = settings.operatingHours[day];
      final start = _minutesOf(hours?['start']);
      final end = _minutesOf(hours?['end']);
      if (start != null) {
        minStartMinutes = minStartMinutes == null
            ? start
            : (start < minStartMinutes ? start : minStartMinutes);
      }
      if (end != null) {
        maxEndMinutes = maxEndMinutes == null
            ? end
            : (end > maxEndMinutes ? end : maxEndMinutes);
      }
    }
  }

  // 営業時間外に登録されたシフトがあっても表示から欠落しないよう、範囲を拡張
  for (final shift in shifts) {
    final start = _minutesOf(shift.startTime);
    final end = _minutesOf(shift.endTime);
    if (start != null) {
      minStartMinutes = minStartMinutes == null
          ? start
          : (start < minStartMinutes ? start : minStartMinutes);
    }
    if (end != null) {
      maxEndMinutes = maxEndMinutes == null
          ? end
          : (end > maxEndMinutes ? end : maxEndMinutes);
    }
  }

  if (minStartMinutes == null ||
      maxEndMinutes == null ||
      minStartMinutes >= maxEndMinutes) {
    return (startHour: 9, endHour: 21);
  }

  return (
    startHour: minStartMinutes ~/ 60,
    endHour: (maxEndMinutes / 60).ceil(),
  );
}

// 指定曜日の営業開始時刻(分)。24時間営業なら0時、設定が無い/不正な場合は9:00を
// デフォルトとする(サーバー側 shift_table_handler.go の dayStartMinutes と同じロジック)
int _dayStartMinutesFor(String day, StoreSettings? settings) {
  if (settings?.is24Hours ?? false) return 0;
  return _minutesOf(settings?.operatingHours[day]?['start']) ?? 9 * 60;
}

// 指定曜日の営業終了時刻(分)。24時間営業なら23:59、設定が無い場合は18:00を
// デフォルトとする(サーバー側 dayEndMinutes と同じロジック)。開始時刻以前になる
// 不正な値(日をまたぐ営業時間など)の場合は startMinutes をそのまま返す
int _dayEndMinutesFor(String day, StoreSettings? settings, int startMinutes) {
  if (settings?.is24Hours ?? false) return 23 * 60 + 59;
  final hours = settings?.operatingHours[day];
  if (hours == null) return 18 * 60;
  final endMinutes = _minutesOf(hours['end']);
  if (endMinutes == null || endMinutes <= startMinutes) return startMinutes;
  return endMinutes;
}

// シフト編集ダイアログの「直」選択肢1件分 (何番目の直かと、その実際の開始/終了時刻)
class _ShiftSlot {
  final int index; // 0-based (画面には index+1 直として表示する)
  final String startTime;
  final String endTime;

  _ShiftSlot(this.index, this.startTime, this.endTime);
}

// 指定曜日の営業時間を、必要人員設定の交代回数+1個のブロックに均等分割し、
// 「直」選択肢の一覧を返す(サーバー側 autoAssignShifts の分割ロジックと同じ)。
// 交代回数の設定が無い曜日は1ブロック(営業時間全体)、営業終了時刻が不明/不正で
// 均等分割できない場合は営業開始時刻から9時間の単一ブロックにフォールバックする
List<_ShiftSlot> _computeShiftSlots(String day, StoreSettings? settings) {
  final dayStart = _dayStartMinutesFor(day, settings);
  final dayEnd = _dayEndMinutesFor(day, settings, dayStart);

  if (dayEnd <= dayStart) {
    final fallbackEnd = (dayStart + 9 * 60).clamp(0, 23 * 60 + 59);
    return [
      _ShiftSlot(0, _formatMinutesLabel(dayStart),
          _formatMinutesLabel(fallbackEnd))
    ];
  }

  final blockCount = (settings?.requiredStaffCount[day]?.shiftChangeCount ??
          0) +
      1;
  final totalMinutes = dayEnd - dayStart;
  return [
    for (var i = 0; i < blockCount; i++)
      _ShiftSlot(
        i,
        _formatMinutesLabel(dayStart + totalMinutes * i ~/ blockCount),
        _formatMinutesLabel(dayStart + totalMinutes * (i + 1) ~/ blockCount),
      ),
  ];
}

const double _hourHeight = 56;
const double _dayColumnWidth = 112;
const double _timeLabelWidth = 52;
const double _headerHeight = 32;

// スタッフ管理画面ページ2: 週間シフト表 (Outlook/Teamsの週表示を参考にしたデザイン)
class ShiftTableView extends HookConsumerWidget {
  final String storeId;

  const ShiftTableView({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = useState(_mondayOf(DateTime.now()));
    final weekStartDate = _formatWeekStartDate(weekStart.value);

    final currentUser = ref.watch(userProfileProvider).valueOrNull;
    final isManager = currentUser?.role == 'manager';

    final shiftTableAsync = ref.watch(
        shiftTableProvider(storeId: storeId, weekStartDate: weekStartDate));
    final staffAsync = ref.watch(staffListProvider(storeId: storeId));
    final storeSettings =
        ref.watch(storeSettingsProvider(storeId: storeId)).valueOrNull;

    final approvedStaff = (staffAsync.value ?? const <Map<String, dynamic>>[])
        .where((s) => s['status'] == 'APPROVED')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeekNavigator(
          weekStart: weekStart.value,
          onPrevious: () => weekStart.value =
              weekStart.value.subtract(const Duration(days: 7)),
          onNext: () =>
              weekStart.value = weekStart.value.add(const Duration(days: 7)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, thickness: 0.5, color: AppColors.border),
        ),
        Expanded(
          child: shiftTableAsync.when(
            loading: () => const Center(
                child:
                    CircularProgressIndicator(color: AppColors.accentPrimary)),
            error: (error, _) => Center(child: Text('エラーが発生しました: $error')),
            data: (table) {
              if (table == null) {
                return _EmptyShiftTable(
                  isManager: isManager,
                  onCreate: () async {
                    try {
                      await ref
                          .read(shiftActionsProvider.notifier)
                          .createTable(storeId, weekStartDate);
                      if (!context.mounted) return;
                      ToastWidget.show(context, 'シフト表を作成しました',
                          type: ToastType.success);
                    } catch (e) {
                      if (!context.mounted) return;
                      ToastWidget.show(
                          context, _describeShiftError(e, 'シフト表作成失敗'),
                          type: ToastType.error);
                    }
                  },
                );
              }

              return _ShiftGridBody(
                storeId: storeId,
                weekStartDate: weekStartDate,
                table: table,
                approvedStaff: approvedStaff,
                storeSettings: storeSettings,
                isManager: isManager,
                currentUserId: currentUser?.id,
              );
            },
          ),
        ),
      ],
    );
  }
}

String _describeShiftError(Object error, String actionLabel) {
  if (error is ApiException) {
    return '$actionLabel: ${error.message}';
  }
  return '予期しないエラーが発生しました: $error';
}

// 週選択ヘッダー: "‹ 9/1(月) - 9/7(日) ›"
class _WeekNavigator extends StatelessWidget {
  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _WeekNavigator({
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final label =
        '${weekStart.month}/${weekStart.day}(${Weekday.labels[0]}) - ${weekEnd.month}/${weekEnd.day}(${Weekday.labels[6]})';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _WeekNavArrowButton(icon: Icons.chevron_left, onPressed: onPrevious),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          _WeekNavArrowButton(icon: Icons.chevron_right, onPressed: onNext),
        ],
      ),
    );
  }
}

// 週送り「‹」「›」用の丸背景アイコンボタン。デフォルトのIconButtonは48x48の
// タップ領域を確保するため縦に間延びして見えるので、コンパクトな円形に収める
class _WeekNavArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _WeekNavArrowButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      color: Colors.white,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        shape: const CircleBorder(),
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// シフト表が未作成の週に表示する空状態
class _EmptyShiftTable extends StatelessWidget {
  final bool isManager;
  final VoidCallback onCreate;

  const _EmptyShiftTable({required this.isManager, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'この週にはまだシフト表が作成されていません。',
            style: TextStyle(fontSize: 15, color: AppColors.textTertiary),
          ),
          if (isManager) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('シフト表を作成'),
            ),
          ],
        ],
      ),
    );
  }
}

// 自動配置時、既存シフトを維持するか全消去するかを選ばせる確認ダイアログ
// ('fill_gaps' または 'replace_all' を返す。キャンセル時は null)
class _AutoAssignModeDialog extends HookWidget {
  const _AutoAssignModeDialog();

  @override
  Widget build(BuildContext context) {
    final selectedMode = useState('fill_gaps');

    return AlertDialog(
      title: const Text('自動配置'),
      content: RadioGroup<String>(
        groupValue: selectedMode.value,
        onChanged: (v) => selectedMode.value = v ?? selectedMode.value,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'この週には既にシフトが登録されています。どのように配置しますか?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            SizedBox(height: 8),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('既存のシフトは維持し、不足分だけ追加'),
              value: 'fill_gaps',
            ),
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('既存のシフトを全て消去して最初から配置'),
              value: 'replace_all',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(selectedMode.value),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            foregroundColor: Colors.white,
          ),
          child: const Text('確認'),
        ),
      ],
    );
  }
}

// シフト表が存在する週のグリッド本体
class _ShiftGridBody extends HookConsumerWidget {
  final String storeId;
  final String weekStartDate;
  final ShiftTable table;
  final List<Map<String, dynamic>> approvedStaff;
  final StoreSettings? storeSettings;
  final bool isManager;
  final String? currentUserId;

  const _ShiftGridBody({
    required this.storeId,
    required this.weekStartDate,
    required this.table,
    required this.approvedStaff,
    required this.storeSettings,
    required this.isManager,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verticalController = useScrollController();
    final horizontalController = useScrollController();

    // 下部ボタンを「自動配置」/「修正依頼を確認」のどちらにするか判定するための件数
    final pendingChangeRequestCount = ref
            .watch(shiftChangeRequestsProvider(
                storeId: storeId, weekStartDate: weekStartDate))
            .valueOrNull
            ?.where((r) => r.isPending)
            .length ??
        0;

    final hourRange = _computeHourRange(storeSettings, table.shifts);
    final gridHeight = (hourRange.endHour - hourRange.startHour) * _hourHeight;

    final staffNames = <String, String>{
      for (final s in approvedStaff) s['_id'] as String: s['user_name'] ?? '不明'
    };
    final staffColors = <String, Color>{
      for (int i = 0; i < approvedStaff.length; i++)
        approvedStaff[i]['_id'] as String:
            AppColors.shiftBlockPalette[i % AppColors.shiftBlockPalette.length]
    };

    // シフトの staffId は(ユーザーIDではなく)store_staff_infoのドキュメントIDのため、
    // 「自分の割当ブロックかどうか」の判定(修正依頼)には currentUserId をそのまま
    // 使えない。approvedStaff から user_id が自分と一致する項目を探し、その _id を使う
    final currentStaffId = approvedStaff.firstWhere(
        (s) => s['user_id'] == currentUserId,
        orElse: () => const <String, dynamic>{})['_id'] as String?;

    // マネージャーが過去にスタッフとして参加した際の store_staff_info が残っている場合は
    // (サーバー側の自動配置/手動保存も同様に)そちらの実名をそのまま使うため、
    // ここでは「approvedStaff の中にマネージャー本人の項目が無い」場合だけ、
    // 実名(+役割表記)のフォールバック項目を補う。実名はサーバーがuser_infoから解決して返す
    final managerId = storeSettings?.managerId;
    final managerHasStaffEntry =
        managerId != null && approvedStaff.any((s) => s['user_id'] == managerId);
    if (managerId != null && managerId.isNotEmpty && !managerHasStaffEntry) {
      final managerName = storeSettings?.managerName;
      staffNames[managerId] = (managerName != null && managerName.isNotEmpty)
          ? '$managerName (マネージャー)'
          : 'マネージャー';
    }

    // シフト編集ダイアログのスタッフ選択肢。マネージャーに割り当てられたシフトを
    // 編集しようとした際、選択肢にマネージャーが無いと DropdownButtonFormField が
    // initialValue不一致でクラッシュするため、承認済みスタッフに加えて含めておく
    // (既に実名の項目がある場合は重複させない)。ただし「シフト表に含める」設定が
    // オフの場合は、新規に選べないよう選択肢からは外す(表示名マッピングは上で
    // 既に埋めているため、過去に割り当て済みのシフトは引き続き実名で表示される)
    final excludeManager = storeSettings?.excludeManagerFromShiftTable ?? false;
    final dialogStaffOptions = [
      ...approvedStaff,
      if (!excludeManager &&
          managerId != null &&
          managerId.isNotEmpty &&
          !managerHasStaffEntry)
        {'_id': managerId, 'user_name': staffNames[managerId]},
    ];

    Future<void> runAutoAssign() async {
      // 既存のシフトがある週は、維持/全消去のどちらで配置するかを先に確認する
      String mode;
      if (table.shifts.isNotEmpty) {
        final selectedMode = await showDialog<String>(
          context: context,
          builder: (_) => const _AutoAssignModeDialog(),
        );
        if (selectedMode == null) return;
        mode = selectedMode;
      } else {
        mode = 'replace_all';
      }

      try {
        await ref
            .read(shiftActionsProvider.notifier)
            .autoGenerateShifts(storeId, weekStartDate, mode: mode);
        if (!context.mounted) return;
        ToastWidget.show(context, 'シフトを自動配置しました', type: ToastType.success);
      } catch (e) {
        if (!context.mounted) return;
        ToastWidget.show(context, _describeShiftError(e, '自動配置失敗'),
            type: ToastType.error);
      }
    }

    Future<void> openEditDialog(Shift shift) async {
      final result = await showDialog<_ShiftFormResult>(
        context: context,
        builder: (_) => _ShiftFormDialog(
          approvedStaff: dialogStaffOptions,
          storeSettings: storeSettings,
          initialShift: shift,
        ),
      );
      if (result == null) return;

      if (result.delete) {
        try {
          await ref
              .read(shiftActionsProvider.notifier)
              .deleteShift(storeId, weekStartDate, shift.id);
          if (!context.mounted) return;
          ToastWidget.show(context, 'シフトを削除しました', type: ToastType.success);
        } catch (e) {
          if (!context.mounted) return;
          ToastWidget.show(context, _describeShiftError(e, 'シフト削除失敗'),
              type: ToastType.error);
        }
        return;
      }

      try {
        await ref.read(shiftActionsProvider.notifier).updateShift(
              storeId,
              weekStartDate,
              shift.id,
              staffId: result.staffId,
              day: result.day,
              startTime: result.startTime,
              endTime: result.endTime,
            );
        if (!context.mounted) return;
        ToastWidget.show(context, 'シフトを更新しました', type: ToastType.success);
      } catch (e) {
        if (!context.mounted) return;
        ToastWidget.show(context, _describeShiftError(e, 'シフト更新失敗'),
            type: ToastType.error);
      }
    }

    // スタッフが自分の割当ブロックをタップした時の修正依頼ダイアログ。
    // 他人のブロックをタップしても何も起きない(自分のシフトしか依頼対象にできない)
    Future<void> openChangeRequestDialog(Shift shift) async {
      if (shift.staffId != currentStaffId) return;

      final result = await showDialog<_ChangeRequestFormResult>(
        context: context,
        builder: (_) => _ShiftChangeRequestDialog(
          shift: shift,
          storeSettings: storeSettings,
        ),
      );
      if (result == null) return;

      try {
        await ref.read(shiftActionsProvider.notifier).sendChangeRequest(
              storeId,
              weekStartDate,
              targetShiftId: shift.id,
              fromDay: shift.day,
              fromStartTime: shift.startTime,
              fromEndTime: shift.endTime,
              toDay: result.toDay,
              toStartTime: result.toStartTime,
              toEndTime: result.toEndTime,
            );
        if (!context.mounted) return;
        ToastWidget.show(context, '修正依頼を送信しました', type: ToastType.success);
      } catch (e) {
        if (!context.mounted) return;
        ToastWidget.show(context, _describeShiftError(e, '修正依頼の送信失敗'),
            type: ToastType.error);
      }
    }

    // ブロック(重複クラスタ含む)タップの共通入口。名前ピンポイントではなく
    // ブロックのどこを押しても反応させる。2人以上のブロックでは:
    // - マネージャー: そのブロックにいる人だけの選択肢(スクロールリスト)を出し、
    //   選んだ人の編集ダイアログを開く
    // - スタッフ: 自分の割当がそのブロックに含まれていれば、その依頼ダイアログを開く
    //   (含まれていなければ何もしない)
    Future<void> handleBlockTap(List<Shift> shiftsInBlock) async {
      if (shiftsInBlock.length == 1) {
        final shift = shiftsInBlock.first;
        if (isManager) {
          await openEditDialog(shift);
        } else {
          await openChangeRequestDialog(shift);
        }
        return;
      }

      if (isManager) {
        final selected = await showDialog<Shift>(
          context: context,
          builder: (_) => _ShiftPickerDialog(
            shifts: shiftsInBlock,
            staffNames: staffNames,
            staffColors: staffColors,
          ),
        );
        if (selected == null) return;
        await openEditDialog(selected);
      } else {
        final ownShifts =
            shiftsInBlock.where((s) => s.staffId == currentStaffId);
        if (ownShifts.isEmpty) return;
        await openChangeRequestDialog(ownShifts.first);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChangeRequestsSection(
          storeId: storeId,
          weekStartDate: weekStartDate,
          isManager: isManager,
          currentUserId: currentUserId,
          storeSettings: storeSettings,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _timeLabelWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: _headerHeight),
                      Expanded(
                        child: ClipRect(
                          child: AnimatedBuilder(
                            animation: verticalController,
                            builder: (context, _) {
                              final offset = verticalController.hasClients
                                  ? verticalController.offset
                                  : 0.0;
                              // ClipRect/Expandedから渡されるのは可視ビューポート分の
                              // (グリッド全体より小さい)高さ制約のため、そのままだと
                              // 全時間ラベルを並べるColumnがoverflowする。
                              // OverflowBoxでColumnにグリッド全体の高さを与えて
                              // 自然にレイアウトさせ、はみ出た分はClipRectで視覚的に切り取る
                              return OverflowBox(
                                alignment: Alignment.topLeft,
                                minHeight: 0,
                                maxHeight: gridHeight,
                                child: Transform.translate(
                                  offset: Offset(0, -offset),
                                  child: _TimeLabelsColumn(
                                    startHour: hourRange.startHour,
                                    endHour: hourRange.endHour,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: verticalController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _DayHeaderRow(),
                          _DayGrid(
                            startHour: hourRange.startHour,
                            endHour: hourRange.endHour,
                            gridHeight: gridHeight,
                            shifts: table.shifts,
                            staffNames: staffNames,
                            staffColors: staffColors,
                            onTapBlock: handleBlockTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isManager)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              // 未対応の修正依頼がある間は、自動配置ボタンをその場で「確認」ボタンに
              // 差し替える。自動配置と依頼適用を別々のボタンとして並べると、どちらを
              // 先に押すべきか迷わせてしまうため、1つのボタンに一本化している
              // (依頼が無くなれば自動的に元の自動配置ボタンへ戻る)
              child: pendingChangeRequestCount > 0
                  ? ElevatedButton.icon(
                      onPressed: () => _runApplyChangeRequests(
                          context, ref, storeId, weekStartDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('修正依頼を確認 ($pendingChangeRequestCount件)'),
                    )
                  : ElevatedButton.icon(
                      onPressed: approvedStaff.isEmpty ? null : runAutoAssign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('自動配置'),
                    ),
            ),
          ),
      ],
    );
  }
}

// 週間シフト表に対する修正依頼セクション。特定のシフトブロックにではなく、その週全体に
// 対する自由記述の依頼として扱う(スタッフ→マネージャー)。マネージャーは依頼を見ながら
// 通常のシフト編集機能で直接シフト表を修正し、対応が済んだら「確定」でまとめて処理済みに
// する(編集のたびに処理済み通知が飛ぶと煩わしいため、この区切りは手動)
class _ChangeRequestsSection extends ConsumerWidget {
  final String storeId;
  final String weekStartDate;
  final bool isManager;
  final String? currentUserId;
  final StoreSettings? storeSettings;

  const _ChangeRequestsSection({
    required this.storeId,
    required this.weekStartDate,
    required this.isManager,
    required this.currentUserId,
    required this.storeSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref
            .watch(shiftChangeRequestsProvider(
                storeId: storeId, weekStartDate: weekStartDate))
            .valueOrNull ??
        const <ShiftChangeRequest>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: isManager
          ? _ManagerChangeRequestsBar(
              storeId: storeId,
              weekStartDate: weekStartDate,
              requests: requests,
              storeSettings: storeSettings,
            )
          : _StaffChangeRequestsBar(
              storeId: storeId,
              weekStartDate: weekStartDate,
              currentUserId: currentUserId,
              requests: requests,
              storeSettings: storeSettings,
            ),
    );
  }
}

// マネージャー向け: 依頼件数の確認ボタン + 未対応分をまとめて処理済みにする「確定」ボタン
class _ManagerChangeRequestsBar extends ConsumerWidget {
  final String storeId;
  final String weekStartDate;
  final List<ShiftChangeRequest> requests;
  final StoreSettings? storeSettings;

  const _ManagerChangeRequestsBar({
    required this.storeId,
    required this.weekStartDate,
    required this.requests,
    required this.storeSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = requests.where((r) => r.isPending).length;

    Future<void> resolveAll() async {
      try {
        await ref
            .read(shiftActionsProvider.notifier)
            .resolveChangeRequests(storeId, weekStartDate);
        if (!context.mounted) return;
        ToastWidget.show(context, '修正依頼を処理済みにしました', type: ToastType.success);
      } catch (e) {
        if (!context.mounted) return;
        ToastWidget.show(context, _describeShiftError(e, '修正依頼の処理失敗'),
            type: ToastType.error);
      }
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: requests.isEmpty
                ? null
                : () => _showChangeRequestListDialog(
                    context, storeId, weekStartDate, storeSettings),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text(pendingCount > 0
                ? '修正依頼 $pendingCount件'
                : (requests.isEmpty ? '修正依頼なし' : '修正依頼を確認')),
          ),
        ),
        if (pendingCount > 0) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: resolveAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('確定'),
          ),
        ],
      ],
    );
  }
}

// スタッフ向け: 自分が送った依頼の対応状況(送信自体は自分のシフトブロックをタップして行う)。
// 他スタッフの依頼内容が見えるとプライバシー上好ましくないため、「依頼中 N件」をタップすると
// 自分の依頼だけに絞った一覧(閲覧のみ)を表示する
class _StaffChangeRequestsBar extends StatelessWidget {
  final String storeId;
  final String weekStartDate;
  final String? currentUserId;
  final List<ShiftChangeRequest> requests;
  final StoreSettings? storeSettings;

  const _StaffChangeRequestsBar({
    required this.storeId,
    required this.weekStartDate,
    required this.currentUserId,
    required this.requests,
    required this.storeSettings,
  });

  @override
  Widget build(BuildContext context) {
    final myRequests =
        requests.where((r) => r.staffId == currentUserId).toList();
    final myPendingCount = myRequests.where((r) => r.isPending).length;

    return Row(
      children: [
        const Expanded(
          child: Text(
            '自分のシフトをタップすると修正を依頼できます',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
        if (myRequests.isNotEmpty) ...[
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _showChangeRequestListDialog(
              context,
              storeId,
              weekStartDate,
              storeSettings,
              filterStaffId: currentUserId,
              canDelete: false,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor:
                  myPendingCount > 0 ? AppColors.warning : AppColors.textTertiary,
              side: BorderSide(
                color: myPendingCount > 0
                    ? AppColors.warning.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: Text(
                myPendingCount > 0 ? '依頼中 $myPendingCount件' : '依頼は全て対応済みです'),
          ),
        ],
      ],
    );
  }
}

// 依頼一覧をまとめて表示するダイアログ。マネージャーは全件+削除可、スタッフは
// filterStaffId で自分の依頼だけに絞り、canDelete: false で削除不可の閲覧専用にする
void _showChangeRequestListDialog(
  BuildContext context,
  String storeId,
  String weekStartDate,
  StoreSettings? storeSettings, {
  String? filterStaffId,
  bool canDelete = true,
}) {
  showDialog(
    context: context,
    builder: (_) => _ChangeRequestListDialog(
      storeId: storeId,
      weekStartDate: weekStartDate,
      storeSettings: storeSettings,
      filterStaffId: filterStaffId,
      canDelete: canDelete,
    ),
  );
}

// 「修正依頼を適用」のメインループ。衝突に当たるたびにダイアログで判断を聞き、
// resolutionsに積み増しながら衝突が無くなる(done=true)まで呼び直す。
// 途中でダイアログを閉じても、それまでに適用された分はサーバー側で既にコミット済み。
// シフト表下部の「自動配置」ボタン(未対応の依頼がある間はこちらに差し替わる)から呼ぶ
Future<void> _runApplyChangeRequests(
    BuildContext context, WidgetRef ref, String storeId, String weekStartDate) async {
  final resolutions = <ChangeRequestResolution>[];
  while (true) {
    final ChangeRequestApplyResult result;
    try {
      result = await ref
          .read(shiftActionsProvider.notifier)
          .applyChangeRequests(storeId, weekStartDate, resolutions);
    } catch (e) {
      if (!context.mounted) return;
      ToastWidget.show(context, _describeShiftError(e, '修正依頼の適用失敗'),
          type: ToastType.error);
      return;
    }

    if (result.done) {
      if (!context.mounted) return;
      final message = result.skippedStaleCount > 0
          ? '${result.appliedCount}件適用しました('
              '${result.skippedStaleCount}件は既に処理済みでした)'
          : '${result.appliedCount}件適用しました';
      ToastWidget.show(context, message, type: ToastType.success);
      return;
    }

    if (!context.mounted) return;
    final decision = await showDialog<ChangeRequestResolution>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConflictResolutionDialog(conflict: result.conflict!),
    );
    // マネージャーがダイアログを閉じてウィザードを中断した場合、
    // ここまでの適用分は既にコミット済みのままループを終了する
    if (decision == null) return;
    resolutions.add(decision);
  }
}

// 依頼一覧ダイアログ本体(閲覧・個別削除のみ)。適用は下部の「自動配置」ボタンに
// 一本化したため、ここには置かない。削除のたびに一覧が最新化されるよう、
// 固定リストではなくProviderを直接watchする
class _ChangeRequestListDialog extends ConsumerWidget {
  final String storeId;
  final String weekStartDate;
  final StoreSettings? storeSettings;
  // 指定があれば、そのスタッフの依頼だけに絞る(スタッフ本人向けの表示に使う。他スタッフの
  // 依頼内容が見えるとプライバシー上好ましくないため)
  final String? filterStaffId;
  // false の場合、各行の削除ボタンを出さない(削除はマネージャー専用エンドポイントのため、
  // スタッフに見せると403で失敗する)
  final bool canDelete;

  const _ChangeRequestListDialog({
    required this.storeId,
    required this.weekStartDate,
    required this.storeSettings,
    this.filterStaffId,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRequests = ref
            .watch(shiftChangeRequestsProvider(
                storeId: storeId, weekStartDate: weekStartDate))
            .valueOrNull ??
        const <ShiftChangeRequest>[];
    final requests = filterStaffId == null
        ? allRequests
        : allRequests.where((r) => r.staffId == filterStaffId).toList();

    return AlertDialog(
      title: Text(filterStaffId == null ? '修正依頼一覧' : '自分の修正依頼'),
      content: SizedBox(
        width: 360,
        child: requests.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('修正依頼はありません',
                    style: TextStyle(color: AppColors.textTertiary)),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final req in requests)
                      _ChangeRequestTile(
                        request: req,
                        storeId: storeId,
                        weekStartDate: weekStartDate,
                        storeSettings: storeSettings,
                        canDelete: canDelete,
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

// 衝突1件の解決を求めるダイアログ。conflict.type によって文言/選択肢が変わる
class _ConflictResolutionDialog extends StatelessWidget {
  final ChangeRequestConflict conflict;

  const _ConflictResolutionDialog({required this.conflict});

  @override
  Widget build(BuildContext context) {
    switch (conflict.type) {
      case ChangeRequestConflict.typeSelfOverlap:
        return AlertDialog(
          title: const Text('確認'),
          content: Text(
            '${conflict.staffName}さんは既に別の時間帯にシフトが入っています。\n'
            '${_dayLabel(conflict.toDay)} ${conflict.toStartTime}-${conflict.toEndTime}'
            'へ移動すると時間が重複しますが、本当によろしいですか?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('いいえ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ChangeRequestResolution(
                requestId: conflict.requestId,
                action: ChangeRequestResolution.actionConfirmOverlap,
              )),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('はい'),
            ),
          ],
        );

      case ChangeRequestConflict.typeCapacity:
        return AlertDialog(
          title: const Text('定員が埋まっています'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_dayLabel(conflict.toDay)} ${conflict.toStartTime}-${conflict.toEndTime}'
                  'は既に必要人数が埋まっています。誰と入れ替えますか?',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final c in conflict.candidates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(ChangeRequestResolution(
                          requestId: conflict.requestId,
                          action: ChangeRequestResolution.actionSwap,
                          targetStaffId: c.staffId,
                        )),
                        child: Text('${c.staffName}さんと入れ替える'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ChangeRequestResolution(
                requestId: conflict.requestId,
                action: ChangeRequestResolution.actionSkip,
              )),
              child: const Text('この依頼を見送る'),
            ),
          ],
        );

      case ChangeRequestConflict.typeRequestConflict:
      default:
        return AlertDialog(
          title: const Text('衝突する依頼があります'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_dayLabel(conflict.toDay)} ${conflict.toStartTime}-${conflict.toEndTime}'
                  'を複数人が希望しています。誰を優先しますか?',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final c in conflict.candidates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(ChangeRequestResolution(
                          requestId: conflict.requestId,
                          action: ChangeRequestResolution.actionPrioritize,
                          targetStaffId: c.staffId,
                        )),
                        child: Text(c.staffName),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(ChangeRequestResolution(
                requestId: conflict.requestId,
                action: ChangeRequestResolution.actionSkip,
              )),
              child: const Text('今回は見送る'),
            ),
          ],
        );
    }
  }
}

// 依頼一覧ダイアログの1件分の表示 (依頼者名・現在の割当→希望する割当・対応状況・削除ボタン)
class _ChangeRequestTile extends HookConsumerWidget {
  final ShiftChangeRequest request;
  final String storeId;
  final String weekStartDate;
  final StoreSettings? storeSettings;
  final bool canDelete;

  const _ChangeRequestTile({
    required this.request,
    required this.storeId,
    required this.weekStartDate,
    required this.storeSettings,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting = useState(false);

    final fromLabel = '${_dayLabel(request.fromDay)} '
        '${_slotLabelFor(request.fromDay, request.fromStartTime, request.fromEndTime, storeSettings)}';
    final toLabel = '${_dayLabel(request.toDay)} '
        '${_slotLabelFor(request.toDay, request.toStartTime, request.toEndTime, storeSettings)}';

    Future<void> handleDelete() async {
      isDeleting.value = true;
      try {
        await ref
            .read(shiftActionsProvider.notifier)
            .deleteChangeRequest(storeId, weekStartDate, request.id);
        if (!context.mounted) return;
        ToastWidget.show(context, '修正依頼を削除しました', type: ToastType.success);
      } catch (e) {
        if (!context.mounted) return;
        ToastWidget.show(context, _describeShiftError(e, '修正依頼の削除失敗'),
            type: ToastType.error);
      } finally {
        if (context.mounted) isDeleting.value = false;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: request.isPending
            ? AppColors.warning.withValues(alpha: 0.08)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: request.isPending
              ? AppColors.warning.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.staffName,
                  style:
                      const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                request.isPending ? '未対応' : '対応済み',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      request.isPending ? AppColors.warning : AppColors.success,
                ),
              ),
              if (canDelete)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: isDeleting.value
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          tooltip: '削除',
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textTertiary),
                          onPressed: handleDelete,
                        ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(fromLabel,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward, size: 14),
              ),
              Expanded(
                child: Text(toLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 左側固定の時間ラベル列 ("09:00" 等を1時間ごとに表示)
class _TimeLabelsColumn extends StatelessWidget {
  final int startHour;
  final int endHour;

  const _TimeLabelsColumn({required this.startHour, required this.endHour});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int h = startHour; h < endHour; h++)
          SizedBox(
            height: _hourHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6, top: 2),
              child: Text(
                '${h.toString().padLeft(2, '0')}:00',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ),
          ),
      ],
    );
  }
}

// 曜日ヘッダー行 (月〜日)
class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final label in Weekday.labels)
          Container(
            width: _dayColumnWidth,
            height: _headerHeight,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

// 時間的に重なり合うシフトの塊(クラスタ)。カードを人数分に分割せず、
// 1枚のカードにまとめて表示するための単位
class _ShiftCluster {
  final List<Shift> shifts;
  final int startMinutes; // クラスタ内シフトの開始時刻の最小値
  final int endMinutes; // クラスタ内シフトの終了時刻の最大値

  _ShiftCluster(this.shifts, this.startMinutes, this.endMinutes);
}

// 1日分のシフト一覧を、時間的に重なり合うもの同士でクラスタにまとめる
// (区間マージの標準的なやり方: 開始時刻順に並べ、直前までの塊の最遅終了時刻より
// 前に始まるものは同じ塊とみなして連結していく)
List<_ShiftCluster> _clusterDayShifts(List<Shift> dayShifts) {
  final sorted = [...dayShifts]..sort((a, b) {
      final aStart = _minutesOf(a.startTime) ?? 0;
      final bStart = _minutesOf(b.startTime) ?? 0;
      return aStart.compareTo(bStart);
    });

  final clusters = <_ShiftCluster>[];
  var current = <Shift>[];
  var currentStart = 0;
  var currentEnd = -1;

  void flush() {
    if (current.isEmpty) return;
    clusters.add(_ShiftCluster(current, currentStart, currentEnd));
    current = [];
    currentEnd = -1;
  }

  for (final shift in sorted) {
    final start = _minutesOf(shift.startTime) ?? 0;
    final end = _minutesOf(shift.endTime) ?? start;

    if (current.isNotEmpty && start >= currentEnd) {
      // それまでの塊と時間的に重ならないので確定させ、新しい塊を開始する
      flush();
    }

    if (current.isEmpty) currentStart = start;
    current.add(shift);
    currentEnd = currentEnd < end ? end : currentEnd;
  }
  flush();

  return clusters;
}

// 曜日ごとの時間グリッド + シフトブロック本体
class _DayGrid extends StatelessWidget {
  final int startHour;
  final int endHour;
  final double gridHeight;
  final List<Shift> shifts;
  final Map<String, String> staffNames;
  final Map<String, Color> staffColors;
  // ブロック(重複クラスタ)全体のタップに反応する。1人だけのブロックなら
  // 要素数1のリストで呼ばれる(氏名ピンポイントではなくブロックのどこを押しても反応させるため)
  final void Function(List<Shift> shiftsInBlock)? onTapBlock;

  const _DayGrid({
    required this.startHour,
    required this.endHour,
    required this.gridHeight,
    required this.shifts,
    required this.staffNames,
    required this.staffColors,
    required this.onTapBlock,
  });

  @override
  Widget build(BuildContext context) {
    final gridStartMinutes = startHour * 60;

    return Row(
      children: [
        for (final day in Weekday.values)
          SizedBox(
            width: _dayColumnWidth,
            height: gridHeight,
            child: Stack(
              children: [
                // 背景の時間区切り線
                Column(
                  children: [
                    for (int h = startHour; h < endHour; h++)
                      Container(
                        height: _hourHeight,
                        decoration: const BoxDecoration(
                          border: Border(
                            top:
                                BorderSide(color: AppColors.border, width: 0.5),
                          ),
                        ),
                      ),
                  ],
                ),
                // その曜日のシフトブロック
                // (同時間帯に重なる分はカードを分割せず、1枚にまとめて氏名を列挙する)
                for (final cluster in _clusterDayShifts(
                    shifts.where((s) => s.day == day).toList()))
                  _buildClusterBlock(cluster, gridStartMinutes),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildClusterBlock(_ShiftCluster cluster, int gridStartMinutes) {
    final top =
        ((cluster.startMinutes - gridStartMinutes) / 60.0) * _hourHeight;
    final height =
        ((cluster.endMinutes - cluster.startMinutes) / 60.0) * _hourHeight;

    // 1人だけの場合は従来通り、その人の色で氏名+時間を表示するシンプルなカード
    if (cluster.shifts.length == 1) {
      final shift = cluster.shifts.first;
      final color = staffColors[shift.staffId] ?? AppColors.accentSecondary;
      return Positioned(
        top: top.clamp(0, gridHeight),
        left: 2,
        right: 2,
        height: height.clamp(4, gridHeight),
        child: GestureDetector(
          onTap: onTapBlock == null ? null : () => onTapBlock!([shift]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              // 複数人カード(下記)と表示順・配色を揃えるため、時間帯を上・氏名を下に表示し、
              // 時間帯は氏名より弱いトーン(半透明の白)にして主役の氏名を目立たせる
              children: [
                Text(
                  '${shift.startTime}-${shift.endTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                Text(
                  staffNames[shift.staffId] ?? '不明',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 同時間帯に複数人いる場合: カードを分割せず1枚にまとめ、時間帯+人数を見出しに、
    // 各人の氏名を色ドット付きで縦に列挙する(タップは氏名ごとに反応し編集できる)。
    // カード自体の背景色は特定の1人の色ではなく、専用パレット(groupShiftBlockPalette)
    // からメンバー構成のハッシュ値で選ぶ。同じ組み合わせは常に同じ色、組み合わせが
    // 変われば別の色になるため、全ての重複カードが同じ色一色にならずに区別できる
    final memberKey = (cluster.shifts.map((s) => s.staffId).toList()..sort())
        .join(',');
    final groupColor = AppColors.groupShiftBlockPalette[
        memberKey.hashCode.abs() % AppColors.groupShiftBlockPalette.length];

    return Positioned(
      top: top.clamp(0, gridHeight),
      left: 2,
      right: 2,
      height: height.clamp(4, gridHeight),
      child: GestureDetector(
        onTap: onTapBlock == null
            ? null
            : () => onTapBlock!(cluster.shifts),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: groupColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1人カードの時間帯表示と同じ弱いトーン(半透明の白・非太字)に揃える
                Text(
                  '${_formatMinutesLabel(cluster.startMinutes)}-'
                  '${_formatMinutesLabel(cluster.endMinutes)} '
                  '・${cluster.shifts.length}名',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
                for (final shift in cluster.shifts)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: staffColors[shift.staffId] ??
                                AppColors.accentSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            staffNames[shift.staffId] ?? '不明',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// シフト追加/編集ダイアログの入力結果
class _ShiftFormResult {
  final String staffId;
  final String day;
  final String startTime;
  final String endTime;
  final bool delete;

  _ShiftFormResult({
    required this.staffId,
    required this.day,
    required this.startTime,
    required this.endTime,
    this.delete = false,
  });
}

// シフト追加/編集用ダイアログ (initialShiftがあれば編集モード、削除ボタンも表示)。
// 開始/終了時刻を自由入力させる代わりに、必要人員設定の交代回数から算出した
// 「直(1直/2直…)」を選ばせることで、営業時間・交代設定と矛盾しないシフトだけを
// 作れるようにする(実際の開始/終了時刻は選んだ直から自動的に決まる)
class _ShiftFormDialog extends HookWidget {
  final List<Map<String, dynamic>> approvedStaff;
  final StoreSettings? storeSettings;
  final Shift? initialShift;

  const _ShiftFormDialog({
    required this.approvedStaff,
    required this.storeSettings,
    this.initialShift,
  });

  @override
  Widget build(BuildContext context) {
    final staffId = useState<String?>(initialShift?.staffId ??
        (approvedStaff.isNotEmpty
            ? approvedStaff.first['_id'] as String
            : null));
    final day = useState<String>(initialShift?.day ?? Weekday.monday);

    // 選択中の曜日の営業時間・交代回数から「直」の選択肢一覧を算出する
    // (曜日を切り替えるたびに再計算する)
    final slots = useMemoized(
        () => _computeShiftSlots(day.value, storeSettings), [day.value]);

    // 編集モードでは、既存シフトの開始/終了時刻と一致する直を初期選択する。
    // 一致するものが無ければ(直制導入前に作成された/営業時間外のシフト等)先頭の直とする
    final slotIndex = useState<int>(initialShift == null
        ? 0
        : slots
            .firstWhere(
              (s) =>
                  s.startTime == initialShift!.startTime &&
                  s.endTime == initialShift!.endTime,
              orElse: () => slots.first,
            )
            .index);

    // 曜日切り替えで選択肢の数自体が変わり、選択中indexが範囲外になった場合だけ補正する
    // (同じindexが引き続き選べる場合は「同じN直」を維持し、その曜日の実時間に自動追従させる)
    useEffect(() {
      if (slotIndex.value >= slots.length) {
        slotIndex.value = 0;
      }
      return null;
    }, [slots.length]);

    final errorText = useState<String?>(null);

    void submit() {
      if (staffId.value == null) {
        errorText.value = 'スタッフを選択してください';
        return;
      }
      final slot = slots[slotIndex.value.clamp(0, slots.length - 1)];
      Navigator.of(context).pop(_ShiftFormResult(
        staffId: staffId.value!,
        day: day.value,
        startTime: slot.startTime,
        endTime: slot.endTime,
      ));
    }

    return AlertDialog(
      title: Text(initialShift == null ? 'シフト追加' : 'シフト編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: staffId.value,
              decoration: const InputDecoration(labelText: 'スタッフ'),
              items: [
                for (final s in approvedStaff)
                  DropdownMenuItem(
                    value: s['_id'] as String,
                    child: Text(s['user_name'] ?? '不明'),
                  ),
              ],
              onChanged: (v) => staffId.value = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: day.value,
              decoration: const InputDecoration(labelText: '曜日'),
              items: [
                for (int i = 0; i < Weekday.values.length; i++)
                  DropdownMenuItem(
                    value: Weekday.values[i],
                    child: Text(Weekday.labels[i]),
                  ),
              ],
              onChanged: (v) => day.value = v ?? day.value,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: slotIndex.value.clamp(0, slots.length - 1),
              decoration: const InputDecoration(labelText: '直'),
              items: [
                for (final slot in slots)
                  DropdownMenuItem(
                    value: slot.index,
                    child: Text(
                        '${slot.index + 1}直 (${slot.startTime}-${slot.endTime})'),
                  ),
              ],
              onChanged: (v) => slotIndex.value = v ?? slotIndex.value,
            ),
            if (errorText.value != null) ...[
              const SizedBox(height: 8),
              Text(errorText.value!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        if (initialShift != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(_ShiftFormResult(
              staffId: staffId.value ?? '',
              day: day.value,
              startTime: initialShift!.startTime,
              endTime: initialShift!.endTime,
              delete: true,
            )),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('削除'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

// シフト修正依頼ダイアログの入力結果 (希望する変更先。Shift/_ShiftFormResult と
// 同じ day/start_time/end_time 形式)
class _ChangeRequestFormResult {
  final String toDay;
  final String toStartTime;
  final String toEndTime;

  _ChangeRequestFormResult({
    required this.toDay,
    required this.toStartTime,
    required this.toEndTime,
  });
}

// シフト修正依頼ダイアログ。自分の割当ブロックをタップして開く。現在の割当は参考表示のみで、
// 希望する曜日・直を選んで送信する(自由記述は無し。_ShiftFormDialog の曜日/直選択と同じUX)
class _ShiftChangeRequestDialog extends HookWidget {
  final Shift shift;
  final StoreSettings? storeSettings;

  const _ShiftChangeRequestDialog({
    required this.shift,
    required this.storeSettings,
  });

  @override
  Widget build(BuildContext context) {
    final toDay = useState<String>(shift.day);

    // 選択中の希望曜日の営業時間・交代回数から「直」の選択肢一覧を算出する
    final slots = useMemoized(
        () => _computeShiftSlots(toDay.value, storeSettings), [toDay.value]);

    // 初期値は現在の割当と同じ直(一致するものが無ければ先頭の直)
    final slotIndex = useState<int>(slots
        .firstWhere(
          (s) => s.startTime == shift.startTime && s.endTime == shift.endTime,
          orElse: () => slots.first,
        )
        .index);

    // 曜日切り替えで選択肢の数自体が変わり、選択中indexが範囲外になった場合だけ補正する
    useEffect(() {
      if (slotIndex.value >= slots.length) {
        slotIndex.value = 0;
      }
      return null;
    }, [slots.length]);

    void submit() {
      final slot = slots[slotIndex.value.clamp(0, slots.length - 1)];
      Navigator.of(context).pop(_ChangeRequestFormResult(
        toDay: toDay.value,
        toStartTime: slot.startTime,
        toEndTime: slot.endTime,
      ));
    }

    return AlertDialog(
      title: const Text('シフト修正依頼'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '現在: ${_dayLabel(shift.day)} ${shift.startTime}-${shift.endTime}',
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: toDay.value,
              decoration: const InputDecoration(labelText: '希望する曜日'),
              items: [
                for (int i = 0; i < Weekday.values.length; i++)
                  DropdownMenuItem(
                    value: Weekday.values[i],
                    child: Text(Weekday.labels[i]),
                  ),
              ],
              onChanged: (v) => toDay.value = v ?? toDay.value,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: slotIndex.value.clamp(0, slots.length - 1),
              decoration: const InputDecoration(labelText: '希望する直'),
              items: [
                for (final slot in slots)
                  DropdownMenuItem(
                    value: slot.index,
                    child: Text(
                        '${slot.index + 1}直 (${slot.startTime}-${slot.endTime})'),
                  ),
              ],
              onChanged: (v) => slotIndex.value = v ?? slotIndex.value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentPrimary,
            foregroundColor: Colors.white,
          ),
          child: const Text('依頼する'),
        ),
      ],
    );
  }
}

// 2人以上が重なるブロックをタップした際に出す、対象を絞り込むための選択ダイアログ
// (マネージャー専用)。そのブロックにいる人だけをスクロールリストで見せ、選んだ人の
// シフトを編集ダイアログに渡す
class _ShiftPickerDialog extends StatelessWidget {
  final List<Shift> shifts;
  final Map<String, String> staffNames;
  final Map<String, Color> staffColors;

  const _ShiftPickerDialog({
    required this.shifts,
    required this.staffNames,
    required this.staffColors,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('編集するスタッフを選択'),
      content: SizedBox(
        width: 320,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: shifts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final shift = shifts[index];
              return ListTile(
                leading: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        staffColors[shift.staffId] ?? AppColors.accentSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(staffNames[shift.staffId] ?? '不明'),
                subtitle: Text('${shift.startTime}-${shift.endTime}'),
                onTap: () => Navigator.of(context).pop(shift),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
