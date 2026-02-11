import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/staff_management_page/staff_management_viewmodel.dart';
import 'package:yoyaku_mate_provider/constants/staff_status.dart';

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

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // エラーは ProfileScreen で共通処理される場合が多いが、
    // ここでもリストが空でエラーがある場合の表示などを考慮
    if (vm.staffList.isEmpty) {
      if (vm.errorMessage != null) {
        return Center(
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
        );
      }
      return const Center(
          child: Text(
        '現在登録されているメンバーはいません。',
        style: TextStyle(fontSize: 16, color: AppColors.textTertiary),
      ));
    }

    return ListView.builder(
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
            ],

            // const SizedBox(height: 8),
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
