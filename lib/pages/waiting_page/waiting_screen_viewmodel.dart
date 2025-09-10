import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/waiting_list.dart';
import '../../services/api_exception.dart';
import '../../services/waiting_service.dart';
import '../../widgets/common_widgets/custom_snack_bar.dart';

class WaitingScreenViewModel extends ChangeNotifier {
  final WaitingService _waitingService;
  final String storeId;

  WaitingScreenViewModel(
      {required this.storeId, required WaitingService waitingService})
      : _waitingService = waitingService {
    loadWaitingList();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // 全ての楽観的アップデートの為の汎用フラグ
  bool _isPerformingOptimisticUpdate = false;

  String? _error;
  String? get error => _error;

  List<WaitingList> _waitingList = [];
  List<WaitingList> get waitingList => _waitingList;

  int get waitingCount => _waitingList
      .where((item) => item.status == 'waiting' || item.status == 'notified')
      .length;

  // 最後入場時間計算ロジック
  String get lastEntryTimeFormatted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? lastEntryTime;
    for (var item in _waitingList) {
      if (item.entryTime != null) {
        final entryDate = DateTime(
            item.entryTime!.year, item.entryTime!.month, item.entryTime!.day);
        if (entryDate.isAtSameMomentAs(today)) {
          if (lastEntryTime == null || item.entryTime!.isAfter(lastEntryTime)) {
            lastEntryTime = item.entryTime;
          }
        }
      }
    }

    if (lastEntryTime == null) return "--:--";

    final jst = lastEntryTime.toUtc().add(const Duration(hours: 9));
    return "${jst.hour.toString().padLeft(2, '0')}:${jst.minute.toString().padLeft(2, '0')}";
  }

  StreamSubscription? _waitingListSubscription;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> loadWaitingList() async {
    _setLoading(true);
    _setError(null);
    _waitingListSubscription?.cancel();

    try {
      final initialData = await _waitingService.fetchWaitingCustomers(storeId);
      _waitingList = initialData;

      _waitingService.startPolling(storeId);
      _waitingListSubscription = _waitingService.waitingListStream.listen(
        (updatedList) {
          // 汎用フラグを確認し、ポーリングデータ上書き防止
          if (!_isPerformingOptimisticUpdate) {
            _waitingList = updatedList;
            _error = null;
            notifyListeners();
          }
        },
        onError: (e) => _handleStreamError(e),
      );
    } on ApiException catch (e) {
      _handleStreamError(e);
    } finally {
      _setLoading(false);
    }
  }

  void _handleStreamError(dynamic e) {
    if (e.toString().contains("data\":null")) {
      _waitingList = [];
      _error = null;
    } else {
      _error = 'データ処理中エラーが発生しました';
    }
    notifyListeners();
  }

  Future<void> addWaitingItem(
      BuildContext context, Map<String, dynamic> data) async {
    _isPerformingOptimisticUpdate = true;
    try {
      final newWaitingItem = await _waitingService.createWaitingListItem(
        storeId: storeId,
        // customerName: data['customerName'],
        partySize: data['partySize'],
        nationality: data['nationality'],
        contact: data['contact'],
        notes: data['notes'],
      );

      _waitingList.add(newWaitingItem);
      notifyListeners();

      if (context.mounted) {
        CustomSnackBar.show(context,
            message: '待機が正常に追加されました', status: SnackBarStatus.success);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context,
            message: '추가 실패: ${e.message}', status: SnackBarStatus.error);
      }
      // 失敗時、サーバーデータと同期化のためリストを再呼出
      await loadWaitingList();
    } finally {
      _isPerformingOptimisticUpdate = false;
    }
  }

  Future<void> updateWaitingStatus(
      BuildContext context, String waitingId, String newStatus) async {
    _isPerformingOptimisticUpdate = true;

    final itemIndex =
        _waitingList.indexWhere((item) => item.waitingId == waitingId);
    if (itemIndex == -1) {
      _isPerformingOptimisticUpdate = false;
      return;
    }
    final originalItem = _waitingList[itemIndex];

    try {
      // ローカルデータを先に修正し、UI 即アップデート (Optimistic Update)
      final updatedItem =
          originalItem.copyWith(status: newStatus, updatedAt: DateTime.now());
      _waitingList[itemIndex] = updatedItem;
      notifyListeners();

      // サーバーへ実際に作業を要請
      await _waitingService.updateWaitingStatus(
          storeId: storeId, waitingId: waitingId, status: newStatus);

      String message = '';
      if (newStatus == 'notified') message = 'お客様を呼び出しました';
      if (newStatus == 'completed') message = '入店処理が完了しました';
      if (context.mounted) {
        CustomSnackBar.show(context,
            message: message, status: SnackBarStatus.success);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context,
            message: 'ステータスアップデート失敗: ${e.message}',
            status: SnackBarStatus.error);
      }
      // 失敗時、UI を以前の状態にロールバック
      _waitingList[itemIndex] = originalItem;
      notifyListeners();
    } finally {
      _isPerformingOptimisticUpdate = false;
    }
  }

  Future<void> clearWaitingList(BuildContext context) async {
    _isPerformingOptimisticUpdate = true;

    // ロールバックに備えて以前リスト保存
    final originalList = List<WaitingList>.from(_waitingList);

    try {
      // ローカルデータを先に修正し、UI 即アップデート
      _waitingList.clear();
      notifyListeners();

      // サーバーへ実際に作業を要請
      await _waitingService.clearWaitingList(storeId);

      if (context.mounted) {
        CustomSnackBar.show(context,
            message: '待機目録を初期化しました', status: SnackBarStatus.success);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context,
            message: '初期化失敗: ${e.message}', status: SnackBarStatus.error);
      }
      // 失敗時、UI を以前の状態にロールバック
      _waitingList = originalList;
      notifyListeners();
    } finally {
      _isPerformingOptimisticUpdate = false;
    }
  }

  Future<void> generateAndSaveQrPdf(BuildContext context, String data) async {
    try {
      final qrImage = await QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      ).toImageData(400.0);

      if (qrImage == null) throw Exception('QRコードイメージ生成失敗');

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pw.MemoryImage(qrImage.buffer.asUint8List())),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final fileName = 'QRCode_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(pdfBytes);
          if (context.mounted) {
            CustomSnackBar.show(context,
                message: 'PDFがダウンロードフォルダに保存されました',
                status: SnackBarStatus.success);
          }
        }
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context,
            message: 'PDF 生成中エラー発生: $e', status: SnackBarStatus.error);
      }
    }
  }

  @override
  void dispose() {
    _waitingListSubscription?.cancel();
    _waitingService.dispose();
    super.dispose();
  }
}
