import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/profile_page/profile_screen_viewmodel.dart';
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
      context.read<ProfileScreenViewModel>().fetchStoreStaff(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileScreenViewModel>();

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
      return const Center(child: Text('スタッフがいません'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vm.staffList.length,
      itemBuilder: (context, index) {
        final staff = vm.staffList[index];
        final status = staff['status'];
        // final isPending = status == StaffStatus.pending; // Not strictly needed if we switch on status or check specific cases

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    _buildStatusChip(status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 承認済みの場合: 拒否ボタンを表示 (承認取り消し)
                    if (status == StaffStatus.approved)
                      OutlinedButton(
                        onPressed: () => vm.updateStoreStaffStatus(
                            widget.storeId, staff['_id'], StaffStatus.rejected),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('承認取り消し'),
                      ),

                    // 承認待ちの場合: 拒否と承認ボタンを表示
                    if (status == StaffStatus.pending) ...[
                      OutlinedButton(
                        onPressed: () => vm.updateStoreStaffStatus(
                            widget.storeId, staff['_id'], StaffStatus.rejected),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('拒否'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => vm.updateStoreStaffStatus(
                            widget.storeId, staff['_id'], StaffStatus.approved),
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
                        onPressed: () => vm.updateStoreStaffStatus(
                            widget.storeId, staff['_id'], StaffStatus.approved),
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
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case StaffStatus.approved:
        color = Colors.green;
        label = '承認済み';
        break;
      case StaffStatus.pending:
        color = Colors.orange;
        label = '承認待ち';
        break;
      case StaffStatus.rejected:
        color = Colors.red;
        label = '拒否済み';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
