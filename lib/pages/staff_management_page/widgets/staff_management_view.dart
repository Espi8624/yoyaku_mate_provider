import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/staff_management_page/staff_management_viewmodel.dart';
import 'package:yoyaku_mate_provider/constants/staff_status.dart';
import 'package:yoyaku_mate_provider/constants/time_block.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/dialogs/day_availability_dialog.dart';

class StaffManagementView extends StatefulWidget {
  final String storeId;

  const StaffManagementView({super.key, required this.storeId});

  @override
  State<StaffManagementView> createState() => _StaffManagementViewState();
}

class _StaffManagementViewState extends State<StaffManagementView> {
  @override
  void initState() {
    super.initState();
    // 画面表示時にデータをロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffManagementViewModel>().fetchStoreStaff(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StaffManagementViewModel>();

    return Stack(
      children: [
        if (vm.errorMessage != null && vm.staffList.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('エラーが発生しました: ${vm.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => vm.fetchStoreStaff(widget.storeId),
                  child: const Text('再試行'),
                ),
              ],
            ),
          )
        else if (vm.staffList.isEmpty && vm.errorMessage == null)
          const Center(
              child: Text(
            '現在登録されているメンバーはいません。',
            style: TextStyle(fontSize: 16, color: AppColors.textTertiary),
          ))
        else if (vm.staffList.isNotEmpty)
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: vm.staffList.length,
            itemBuilder: (context, index) {
              final staff = vm.staffList[index];

              return _StaffCard(
                staff: staff,
                storeId: widget.storeId,
                vm: vm,
              );
            },
          ),

        // Show common loading indicator on top
        if (vm.isLoading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.accentPrimary)),
      ],
    );
  }

  // Helper method moved to inside _StaffCard or kept global if stateless
}

class _StaffCard extends StatefulWidget {
  final Map<String, dynamic> staff;
  final String storeId;
  final StaffManagementViewModel vm;

  const _StaffCard({
    required this.staff,
    required this.storeId,
    required this.vm,
  });

  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> {
  bool _isExpanded = false;
  bool _isAvailabilityExpanded = false;

  // 曜日バッジタップ時、その曜日1日分だけの勤務可能時間帯を編集するダイアログを表示
  Future<void> _showDayAvailabilityDialog(
      BuildContext context, String day, String dayLabel) async {
    final availability =
        widget.staff['availability'] as Map<String, dynamic>? ?? {};
    final currentBlocks =
        (availability[day] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            <String>[];

    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) =>
          DayAvailabilityDialog(dayLabel: dayLabel, initialBlocks: currentBlocks),
    );

    if (result != null) {
      // 他の曜日の値は維持したまま、タップされた曜日だけを更新してサーバーに送信
      final updatedAvailability = {
        for (final d in Weekday.values)
          d: (availability[d] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[],
      };
      updatedAvailability[day] = result;

      await widget.vm.updateStoreStaffAvailability(
          widget.storeId, widget.staff['_id'], updatedAvailability);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.staff['status'];

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
                      widget.staff['user_name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.staff['email'] ?? '',
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

            // 承認済みの場合のみ「権限設定」の展開ボタンを表示
            if (status == StaffStatus.approved) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
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
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              if (_isExpanded) ...[
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
                      value: (widget.staff['permissions'] as List<dynamic>?)
                              ?.contains('menu_edit') ??
                          false,
                      onChanged: (value) {
                        final currentPermissions =
                            (widget.staff['permissions'] as List<dynamic>?)
                                    ?.map((e) => e.toString())
                                    .toList() ??
                                [];
                        if (value) {
                          currentPermissions.add('menu_edit');
                        } else {
                          currentPermissions.remove('menu_edit');
                        }
                        widget.vm.updateStoreStaffPermissions(widget.storeId,
                            widget.staff['_id'], currentPermissions);
                      },
                      activeColor: AppColors.accentPrimary,
                    ),
                  ],
                ),
              ],

              // 勤務可能日は「権限設定」とは独立して開閉可能
              const SizedBox(height: 12),
              const Divider(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAvailabilityExpanded = !_isAvailabilityExpanded;
                  });
                },
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
                      _isAvailabilityExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              if (_isAvailabilityExpanded) ...[
                const SizedBox(height: 12),
                const Text(
                  '曜日をタップして編集',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                _AvailabilitySummary(
                  availability:
                      widget.staff['availability'] as Map<String, dynamic>? ??
                          {},
                  onDayTap: (day, dayLabel) =>
                      _showDayAvailabilityDialog(context, day, dayLabel),
                ),
              ],
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 承認済みの場合: 拒否ボタンを表示 (承認取り消し)
                if (status == StaffStatus.approved)
                  ElevatedButton(
                    onPressed: () => widget.vm.updateStoreStaffStatus(
                        widget.storeId,
                        widget.staff['_id'],
                        StaffStatus.rejected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rejected,
                      foregroundColor: AppColors.textPrimaryLight,
                    ),
                    child: const Text('承認取り消し'),
                  ),

                // 承認待ちの場合: 拒否と承認ボタンを表示
                if (status == StaffStatus.pending) ...[
                  OutlinedButton(
                    onPressed: () => widget.vm.updateStoreStaffStatus(
                        widget.storeId,
                        widget.staff['_id'],
                        StaffStatus.rejected),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('拒否'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => widget.vm.updateStoreStaffStatus(
                        widget.storeId,
                        widget.staff['_id'],
                        StaffStatus.approved),
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
                    onPressed: () => widget.vm.updateStoreStaffStatus(
                        widget.storeId,
                        widget.staff['_id'],
                        StaffStatus.approved),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('再承認'),
                  ),
              ],
            ),
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
              color: isAvailable
                  ? AppColors.accentPrimary.withOpacity(0.15)
                  : Colors.grey.shade200,
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
                color: isAvailable ? AppColors.accentPrimary : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }
}
