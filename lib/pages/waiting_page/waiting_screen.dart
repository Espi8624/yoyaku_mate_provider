import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/waiting_list.dart';
import 'package:yoyaku_mate_provider/services/waiting_service.dart';
import 'package:yoyaku_mate_provider/services/store_settings_service.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/base_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_dialogs/confirmation_dialog.dart';
import 'package:yoyaku_mate_provider/widgets/common_widgets/loading_indicator.dart';
import 'widgets/dialogs/add_waiting_dialog.dart';
import 'widgets/qr_code_button.dart';
import 'widgets/waiting_action_buttons.dart';
import 'widgets/waiting_list_panel.dart';
import 'widgets/waiting_status_area.dart';
import 'waiting_screen_viewmodel.dart';

class WaitingScreen extends StatelessWidget {
  final String storeId;
  const WaitingScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        return WaitingScreenViewModel(
          storeId: storeId,
          waitingService: WaitingService(),
          settingsService: context.read<StoreSettingsService>(),
        );
      },
      child: const _WaitingView(),
    );
  }
}

class _WaitingView extends StatelessWidget {
  const _WaitingView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WaitingScreenViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double mobileBreakpoint = 700;
        final bool isMobile = constraints.maxWidth < mobileBreakpoint;
        String qrCodeData =
            "https://yoyaku-mate.vercel.app/waiting-screen-flow?store_id=${vm.storeId}";
        if (vm.qrToken != null) {
          qrCodeData += "&v_token=${vm.qrToken}";
        }

        if (vm.isLoading) {
          return const Center(child: LoadingIndicator());
        }
        if (vm.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(vm.error!, style: const TextStyle(color: AppColors.error)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: vm.loadWaitingList,
                  child: const Text('再試行'),
                ),
              ],
            ),
          );
        }

        if (isMobile) {
          // mobile layout
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '待機中のお客様リスト',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.delete_sweep_rounded),
                                onPressed: () =>
                                    _showClearConfirmationDialog(context)),
                            QRCodeButton(data: qrCodeData),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none, // 影が切れないようにする
                      children: [
                        // 待機目録リスト
                        Positioned.fill(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFilterBar(context, vm),
                                Expanded(
                                  child: WaitingListPanel(
                                    waitingList: vm.filteredWaitingList,
                                    onRefresh: vm.loadWaitingList,
                                    onItemAction: (item) =>
                                        _showStatusBasedDialog(context, item),
                                    bottomPadding: 85,
                                    qrToken: vm.qrToken,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: 16.0, bottom: 16.0),
                                child: FloatingActionButton(
                                  onPressed: () =>
                                      _showAddWaitingDialog(context),
                                  backgroundColor: AppColors.accentPrimary,
                                  child: const Icon(Icons.add,
                                      color: Colors.white),
                                ),
                              ),
                              const WaitingStatusArea(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // desktop layout
          return Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            const Text(
                              '待機中のお客様リスト',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Tooltip(
                              message: "更新",
                              child: ElevatedButton(
                                onPressed: vm.loadWaitingList,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.textPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(16),
                                  minimumSize: Size.zero,
                                ),
                                child: const Icon(Icons.refresh,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            WaitingActionButtons(
                              onAddWaiting: () =>
                                  _showAddWaitingDialog(context),
                              onClearAll: () =>
                                  _showClearConfirmationDialog(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            QRCodeButton(data: qrCodeData),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFilterBar(context, vm),
                              Expanded(
                                child: WaitingListPanel(
                                  waitingList: vm.filteredWaitingList,
                                  onRefresh: vm.loadWaitingList,
                                  onItemAction: (item) =>
                                      _showStatusBasedDialog(context, item),
                                  qrToken: vm.qrToken,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          flex: 1,
                          child: WaitingStatusArea(isInitiallyExpanded: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> _showAddWaitingDialog(BuildContext context) async {
    final vm = context.read<WaitingScreenViewModel>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddWaitingDialog(
        storeId: vm.storeId,
        enableMenuSelection: vm.enableMenuSelection,
      ),
    );
    if (result != null && context.mounted) {
      await vm.addWaitingItem(context, result);
    }
  }

  Future<void> _showClearConfirmationDialog(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '待機目録初期化',
      content: '現在の待機目録を全て初期化しますか？\nこの操作は取り消しできません。',
    );
    if (confirmed == true && context.mounted) {
      await context.read<WaitingScreenViewModel>().clearWaitingList(context);
    }
  }

  Future<void> _showCancelConfirmationDialog(
      BuildContext context, WaitingList item) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: '待機取消',
      content: 'このお客様の待機を取消しますか？\nこの操作は取り消しできません。',
    );
    if (confirmed == true && context.mounted) {
      await context
          .read<WaitingScreenViewModel>()
          .updateWaitingStatus(context, item.waitingId, 'cancelled');
    }
  }

  Widget _buildFilterBar(BuildContext context, WaitingScreenViewModel vm) {
    final filters = [
      {'label': 'すべて', 'value': 'all'},
      {'label': '待機中', 'value': 'waiting'},
      {'label': '入店済', 'value': 'completed'},
      {'label': '取消済', 'value': 'cancelled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: filters.map((f) {
          final isSelected = vm.selectedFilter == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  vm.setFilter(f['value']!);
                }
              },
              selectedColor: AppColors.accentPrimary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[100],
              showCheckmark: false,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStatusBasedDialog(BuildContext context, WaitingList item) {
    switch (item.status) {
      case 'waiting':
        _showNotificationDialog(context, item);
        break;
      case 'notified':
        _showEntryConfirmationDialog(context, item);
        break;
      default:
        _showInfoDialog(context, item);
        break;
    }
  }

  String _formatTime(DateTime time) {
    final jstTime = time.toUtc().add(const Duration(hours: 9));
    return "${jstTime.hour.toString().padLeft(2, '0')}:${jstTime.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildMenuItemsDisplay(WaitingList item) {
    if (item.menuItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('事前注文:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        ...item.menuItems.map((menu) => Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
              child: Text(
                '• ${menu.name} x${menu.quantity}',
                style: const TextStyle(fontSize: 16),
              ),
            )),
      ],
    );
  }

  Future<void> _showNotificationDialog(
      BuildContext context, WaitingList item) async {
    final vm = context.read<WaitingScreenViewModel>();
    final notesText =
        (item.notes != null && item.notes!.isNotEmpty) ? item.notes! : null;

    await showDialog(
      context: context,
      builder: (ctx) => BaseDialog(
        title: '呼出',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('予約番号: ${item.waitingId}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('#${item.queueNumber.toString()} 番',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('様を呼出します。', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            const Text('最後に詳細をご確認ください。', style: TextStyle(fontSize: 16)),
            Text('${item.partySize}名',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (notesText != null)
              Text(notesText,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            _buildMenuItemsDisplay(item),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx)
                            .pop(); // Close notification dialog first? Or keep?
                        // If I close it, context might be lost if using ctx.
                        // I should probably use `context` from outer scope or check mounted.
                        // The user probably wants to cancel from this dialog.
                        // Let's call cancel confirmation.
                        _showCancelConfirmationDialog(context, item);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('待機取消'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Call Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        vm.updateWaitingStatus(ctx, item.waitingId, 'notified');
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('呼出'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEntryConfirmationDialog(
      BuildContext context, WaitingList item) async {
    final vm = context.read<WaitingScreenViewModel>();
    final contactText = (item.contact != null && item.contact!.isNotEmpty)
        ? item.contact!
        : null;
    final notesText =
        (item.notes != null && item.notes!.isNotEmpty) ? item.notes! : null;

    await showDialog(
      context: context,
      builder: (ctx) => BaseDialog(
        title: '入店確認',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('予約番号: ${item.waitingId}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('#${item.queueNumber.toString()} 番',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('様', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Text('${item.partySize}名',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (contactText != null)
              Text('連絡先: $contactText', style: const TextStyle(fontSize: 16)),
            if (notesText != null)
              Text('メモ: $notesText', style: const TextStyle(fontSize: 16)),
            _buildMenuItemsDisplay(item),
            const SizedBox(height: 16),
            const Text('入店処理を行いますか？',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  vm.updateWaitingStatus(ctx, item.waitingId, 'completed');
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('入店完了'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInfoDialog(BuildContext context, WaitingList item) async {
    String formattedRegistrationTime = _formatTime(item.registrationTime);
    String? formattedCalledTime =
        item.calledTime != null ? _formatTime(item.calledTime!) : null;
    String? formattedEntryTime =
        item.entryTime != null ? _formatTime(item.entryTime!) : null;
    final contactText = (item.contact != null && item.contact!.isNotEmpty)
        ? item.contact!
        : null;
    final notesText =
        (item.notes != null && item.notes!.isNotEmpty) ? item.notes! : null;

    await showDialog(
      context: context,
      builder: (ctx) => BaseDialog(
        title: '情報',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('予約番号: ${item.waitingId}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${item.queueNumber} 番',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('様', style: TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Text('${item.partySize}名',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (contactText != null)
              Text('連絡先: $contactText', style: const TextStyle(fontSize: 16)),
            if (notesText != null)
              Text('メモ: $notesText', style: const TextStyle(fontSize: 16)),
            _buildMenuItemsDisplay(item),
            const SizedBox(height: 8),
            Text('登録時間: $formattedRegistrationTime',
                style: const TextStyle(fontSize: 16)),
            if (formattedCalledTime != null)
              Text('呼出時間: $formattedCalledTime',
                  style: const TextStyle(fontSize: 16)),
            if (formattedEntryTime != null)
              Text('入店時間: $formattedEntryTime',
                  style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
