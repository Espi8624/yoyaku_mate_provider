import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/waiting_list.dart';
import '../../services/api_exception.dart';
import '../../services/waiting_service.dart';
import '../../services/store_settings_service.dart';
import '../../widgets/common_widgets/toast_widget.dart';

class WaitingScreenViewModel extends ChangeNotifier
    with WidgetsBindingObserver {
  final WaitingService _waitingService;
  final StoreSettingsService _settingsService;
  final String storeId;

  int _estimatedWaitTimePerTeam = 10; // Default 10 min

  WaitingScreenViewModel({
    required this.storeId,
    required WaitingService waitingService,
    required StoreSettingsService settingsService,
  })  : _waitingService = waitingService,
        _settingsService = settingsService {
    WidgetsBinding.instance.addObserver(this);
    // コンストラクタ内での notifyListeners() 呼び出しを防ぐため、遅延実行
    Future.microtask(() {
      _loadStoreSettings();
      loadWaitingList();
    });
  }

  Future<void> _loadStoreSettings() async {
    try {
      final settings = await _settingsService.fetchStoreSettings(storeId);
      if (settings.waitingPolicy.estimatedWaitTime != null &&
          settings.waitingPolicy.estimatedWaitTime! > 0) {
        _estimatedWaitTimePerTeam = settings.waitingPolicy.estimatedWaitTime!;
      }
      _enableMenuSelection = settings.waitingPolicy.enableMenuSelection;
      notifyListeners();
    } catch (e) {
      // print('Failed to load store settings: $e');
      // Default remains 10
    }
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // 全ての楽観的アップデートの為の汎用フラグ
  bool _isPerformingOptimisticUpdate = false;

  String? _error;
  String? get error => _error;

  List<WaitingList> _waitingList = [];
  List<WaitingList> get waitingList => _waitingList;

  String _selectedFilter = 'all';
  String get selectedFilter => _selectedFilter;

  String? _qrToken;
  String? get qrToken => _qrToken;

  bool _enableMenuSelection = false;
  bool get enableMenuSelection => _enableMenuSelection;

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  List<WaitingList> get filteredWaitingList {
    if (_selectedFilter == 'all') {
      return _waitingList;
    }
    if (_selectedFilter == 'waiting') {
      return _waitingList
          .where(
              (item) => item.status == 'waiting' || item.status == 'notified')
          .toList();
    }
    if (_selectedFilter == 'completed') {
      return _waitingList.where((item) => item.status == 'completed').toList();
    }
    if (_selectedFilter == 'cancelled') {
      return _waitingList.where((item) => item.status == 'cancelled').toList();
    }
    // no_show データは完全に除外
    return _waitingList.where((item) => item.status != 'no_show').toList();
  }

  int get waitingCount =>
      _waitingList.where((item) => item.status == 'waiting').length;

  // 最後入場時間計算ロジック
  String get lastEntryTimeFormatted {
    // Backendが既に「現在の営業日(2:00切り替え)」のリストを返しているため、
    // ここで日付フィルタリングをする必要はない。リスト内で最も新しい entryTime を探すだけで良い。
    DateTime? lastEntryTime;
    for (var item in _waitingList) {
      if (item.entryTime != null) {
        if (lastEntryTime == null || item.entryTime!.isAfter(lastEntryTime)) {
          lastEntryTime = item.entryTime;
        }
      }
    }

    if (lastEntryTime == null) return "--:--";

    // JST表示 (サーバーがUTCで返す場合も考慮して変換、ただしアプリがJST圏内ならtoLocalで十分かもしれないが明確に+9する)
    // entryTimeはDateTime.parseされているので、isUtc=trueなら+9h、localならそのまま...
    // 安全のため toUtc().add(9h) 方式を維持するか、toLocal()を使う。
    // ここでは既存ロジックに合わせて toUtc().add(...) を維持。
    final jst = lastEntryTime.toUtc().add(const Duration(hours: 9));
    return "${jst.hour.toString().padLeft(2, '0')}:${jst.minute.toString().padLeft(2, '0')}";
  }

  // 全体の予想待機時間 (新規顧客が入った場合の時間概算)
  // 実務での一般的なアプローチ: リスト内の「最後の待機時間」または「最大時間」を参照する (Derived State)
  // これにより、バックエンドのロジック(10分か15分かAIか)を意識せずに済む
  String get totalEstimatedWaitTimeFormatted {
    if (_waitingList.isEmpty) return "0分";

    // 待機人数 * 設定された1組あたりの時間
    // waitingCount はローカルで即時更新されるため、これを使うのが確実。
    return "${waitingCount * _estimatedWaitTimePerTeam}分";
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
      // 待機リスト取得の際、QRトークンも一緒に取得
      final results = await Future.wait([
        _waitingService.fetchWaitingCustomers(storeId),
        _waitingService.fetchQRToken(storeId),
      ]);

      final initialData = results[0] as List<WaitingList>;
      final tokenData = results[1] as Map<String, String>;

      _qrToken = tokenData['v_token'];
      // print('DEBUG: Fetched QR Token: $_qrToken'); // Debug log

      // 最新の登録が上に来るように降順ソート
      initialData
          .sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      _waitingList = initialData;

      _waitingService.startPolling(storeId);
      _waitingListSubscription = _waitingService.waitingListStream.listen(
        (updatedList) {
          // 汎用フラグを確認し、ポーリングデータ上書き防止
          if (!_isPerformingOptimisticUpdate) {
            // 最新の登録が上に来るように降順ソート
            updatedList.sort(
                (a, b) => b.registrationTime.compareTo(a.registrationTime));
            _waitingList = updatedList;
            _error = null;
            notifyListeners();
          }
        },
        onError: (e) => _handleStreamError(e),
      );
    } catch (e) {
      if (e is ApiException) {
        _handleStreamError(e);
      } else {
        _setError('データの読み込みに失敗しました: $e');
      }
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
        partySize: data['partySize'] as int,
        nationality: 'unknown',
        contact: data['contact']?.toString() ?? '',
        notes: data['notes']?.toString() ?? '',
        // menuItems: data['menuItems'], // Note: WaitingService needs update to support this param
        // WaitingService has been updated to accept menuItems, but we need to ensure data['menuItems'] is correct type
        // It is collected as List<MenuItem> in dialog.
        menuItems: data['menuItems'] as List<MenuItem>?,
        vToken: _qrToken,
      );

      _waitingList.add(newWaitingItem);
      // 最新の登録が上に来るように降順ソート
      _waitingList
          .sort((a, b) => b.registrationTime.compareTo(a.registrationTime));
      notifyListeners();

      if (context.mounted) {
        ToastWidget.show(context, '待機が正常に追加されました', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = e.toString();

        const String prefix = 'Exception: ';
        if (errorMessage.startsWith(prefix)) {
          errorMessage = errorMessage.substring(prefix.length);
        }
        final finalMessage = errorMessage.trim();

        ToastWidget.show(context, '追加失敗: $finalMessage', type: ToastType.error);
      }
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
      final updatedItem = originalItem.copyWith(
        status: newStatus,
        // notified(呼び出し)の場合は calledTime も更新
        calledTime:
            newStatus == 'notified' ? DateTime.now() : originalItem.calledTime,
        // completed(入店)の場合は entryTime も更新しないと「直前入場時間」が即時反映されない
        entryTime: newStatus == 'completed' ? DateTime.now() : null,
      );
      _waitingList[itemIndex] = updatedItem;
      notifyListeners();

      // サーバーへ実際に作業を要請
      await _waitingService.updateWaitingStatus(
          storeId: storeId, waitingId: waitingId, status: newStatus);

      String message = '';
      if (newStatus == 'notified') message = 'お客様を呼び出しました';
      if (newStatus == 'completed') message = '入店処理が完了しました';
      if (newStatus == 'cancelled') message = '待機を取り消しました';
      if (context.mounted) {
        // messageが空でなければ表示 (一応空チェックを入れるか、ToastWidget側で空なら表示しないかだが、ここでは空なら表示しないようにガードする方が丁寧かも)
        if (message.isNotEmpty) {
          ToastWidget.show(context, message, type: ToastType.success);
        }
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ToastWidget.show(context, 'ステータスアップデート失敗: ${e.message}',
            type: ToastType.error);
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
        ToastWidget.show(context, '待機目録を初期化しました', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ToastWidget.show(context, '初期化失敗: ${e.message}', type: ToastType.error);
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
      // QRコードのイメージデータを生成 (共通)
      final qrPainter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      final qrImage = await qrPainter.toImageData(800.0); // 高解像度で生成
      if (qrImage == null) throw Exception('QRコードイメージ生成失敗');
      final pngBytes = qrImage.buffer.asUint8List();

      // モバイル (Android/iOS) の場合: ギャラリーに保存して開く
      if (Platform.isAndroid || Platform.isIOS) {
        // 権限は gal が内部でハンドリングまたは要請するが、事前に許可が必要な場合もある
        // gal は putImageBytes で保存可能
        await Gal.putImageBytes(pngBytes, name: "yoyaku_mate_qr");

        if (context.mounted) {
          ToastWidget.show(context, 'QRコードがギャラリーに保存されました',
              type: ToastType.success);
        }

        // ギャラリーアプリを開く
        await Gal.open();
        return;
      }

      // デスクトップの場合: PDFまたは画像としてダウンロードフォルダに保存
      // 既存のPDFロジックを維持 (印刷用にはPDFが便利)
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pw.MemoryImage(pngBytes)),
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
            ToastWidget.show(context, 'PDFがダウンロードフォルダに保存されました',
                type: ToastType.success);
          }
        }
      } else {
        // Webなどのフォールバック (基本ここには来ないはずだが)
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      }
    } catch (e) {
      if (context.mounted) {
        ToastWidget.show(context, '保存処理中にエラーが発生しました: $e',
            type: ToastType.error);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // アプリがフォアグラウンドに戻った時にデータを再取得＆SSE再接続
      loadWaitingList();
    }
  }

  @override
  void dispose() {
    _waitingListSubscription?.cancel();
    _waitingService.dispose();
    super.dispose();
  }
}
