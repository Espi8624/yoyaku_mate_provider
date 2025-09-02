import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/models/waiting_list.dart';
import 'package:yoyaku_mate_provider/services/waiting_service.dart';
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
      create: (_) => WaitingScreenViewModel(
        storeId: storeId,
        waitingService: WaitingService(),
      ),
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
            appBar: AppBar(
              title: const Text('待機リスト',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              actions: [
                const QRCodeButton(data: 'https://example.com/waiting-screen'),
                IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: () => _showClearConfirmationDialog(context)),
              ],
            ),
            // floatingActionButton: FloatingActionButton(
            //   onPressed: () => _showAddWaitingDialog(context),
            //   backgroundColor: AppColors.accentPrimary,
            //   child: const Icon(Icons.add, color: Colors.white),
            // ),
            body: SafeArea(
              top: false,
              child: Stack(
                children: [
                  // 待機目録リスト
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: WaitingListPanel(
                        waitingList: vm.waitingList,
                        onRefresh: vm.loadWaitingList,
                        onItemAction: (item) =>
                            _showStatusBasedDialog(context, item),
                        bottomPadding: 85,
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
                          padding:
                              const EdgeInsets.only(right: 16.0, bottom: 16.0),
                          child: FloatingActionButton(
                            onPressed: () => _showAddWaitingDialog(context),
                            backgroundColor: AppColors.accentPrimary,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                        const ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          child: WaitingStatusArea(),
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
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        WaitingActionButtons(
                          onAddWaiting: () => _showAddWaitingDialog(context),
                          onClearAll: () =>
                              _showClearConfirmationDialog(context),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: WaitingListPanel(
                            waitingList: vm.waitingList,
                            onRefresh: vm.loadWaitingList,
                            onItemAction: (item) =>
                                _showStatusBasedDialog(context, item),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        QRCodeButton(
                            data: 'https://example.com/waiting-screen'),
                        SizedBox(height: 10),
                        Expanded(
                          child: WaitingStatusArea(isInitiallyExpanded: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
      builder: (_) => const AddWaitingDialog(),
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
                Text(item.customerName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
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
                Text(item.customerName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Text(' 様', style: TextStyle(fontSize: 16)),
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
                Text(item.customerName,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Text(' 様', style: TextStyle(fontSize: 16)),
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
