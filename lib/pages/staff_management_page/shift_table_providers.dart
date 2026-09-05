// シフト表画面の状態管理 (Riverpod)
//
// staff_management_providers.dart と同じ設計方針:
// - 取得は FutureProvider(shiftTableProvider) で宣言的に扱う (AsyncValue)
//   その週にシフト表が未作成の場合は値が null (=「未作成」状態) になる
// - 更新系アクションは状態を持たない NotifierProvider(shiftActionsProvider) に集約し、
//   成功時は shiftTableProvider を invalidate して再取得させる
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yoyaku_mate_provider/models/shift_change_request.dart';
import 'package:yoyaku_mate_provider/models/shift_table.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';

part 'shift_table_providers.g.dart';

@riverpod
Future<ShiftTable?> shiftTable(
  Ref ref, {
  required String storeId,
  required String weekStartDate,
}) async {
  final service = ref.watch(shiftTableServiceProvider);
  return service.fetchShiftTable(storeId, weekStartDate);
}

// 週間シフト表に対する修正依頼一覧 (特定のシフトブロックにではなく、その週全体に対する
// 自由記述の依頼。スタッフ→マネージャー)
@riverpod
Future<List<ShiftChangeRequest>> shiftChangeRequests(
  Ref ref, {
  required String storeId,
  required String weekStartDate,
}) async {
  final service = ref.watch(shiftTableServiceProvider);
  return service.fetchChangeRequests(storeId, weekStartDate);
}

@riverpod
class ShiftActions extends _$ShiftActions {
  // 状態を持たないアクション専用Notifier
  @override
  void build() {}

  Future<void> createTable(String storeId, String weekStartDate) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.createShiftTable(storeId, weekStartDate);
    ref.invalidate(
        shiftTableProvider(storeId: storeId, weekStartDate: weekStartDate));
  }

  Future<void> addShift(
    String storeId,
    String weekStartDate, {
    required String staffId,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.addShift(
      storeId,
      weekStartDate,
      staffId: staffId,
      day: day,
      startTime: startTime,
      endTime: endTime,
    );
    ref.invalidate(
        shiftTableProvider(storeId: storeId, weekStartDate: weekStartDate));
  }

  Future<void> updateShift(
    String storeId,
    String weekStartDate,
    String shiftId, {
    required String staffId,
    required String day,
    required String startTime,
    required String endTime,
  }) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.updateShift(
      storeId,
      weekStartDate,
      shiftId,
      staffId: staffId,
      day: day,
      startTime: startTime,
      endTime: endTime,
    );
    ref.invalidate(
        shiftTableProvider(storeId: storeId, weekStartDate: weekStartDate));
  }

  Future<void> deleteShift(
      String storeId, String weekStartDate, String shiftId) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.deleteShift(storeId, weekStartDate, shiftId);
    ref.invalidate(
        shiftTableProvider(storeId: storeId, weekStartDate: weekStartDate));
  }

  Future<void> autoGenerateShifts(
    String storeId,
    String weekStartDate, {
    required String mode,
  }) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.autoGenerateShifts(storeId, weekStartDate, mode: mode);
    ref.invalidate(
        shiftTableProvider(storeId: storeId, weekStartDate: weekStartDate));
  }

  // シフトブロックに対する修正依頼を送信 (承認済みスタッフ用)
  Future<void> sendChangeRequest(
    String storeId,
    String weekStartDate, {
    required String targetShiftId,
    required String fromDay,
    required String fromStartTime,
    required String fromEndTime,
    required String toDay,
    required String toStartTime,
    required String toEndTime,
  }) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.createChangeRequest(
      storeId,
      weekStartDate,
      targetShiftId: targetShiftId,
      fromDay: fromDay,
      fromStartTime: fromStartTime,
      fromEndTime: fromEndTime,
      toDay: toDay,
      toStartTime: toStartTime,
      toEndTime: toEndTime,
    );
    ref.invalidate(shiftChangeRequestsProvider(
        storeId: storeId, weekStartDate: weekStartDate));
  }

  // その週の未処理の修正依頼を全て処理済みにする (マネージャー専用。編集のたびではなく、
  // 対応が一段落してから押す「確定」ボタン用)
  Future<void> resolveChangeRequests(
      String storeId, String weekStartDate) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.resolveChangeRequests(storeId, weekStartDate);
    ref.invalidate(shiftChangeRequestsProvider(
        storeId: storeId, weekStartDate: weekStartDate));
  }

  // 未処理の修正依頼を古い順に実際のシフト表へ反映する (マネージャー専用)。衝突に
  // 当たった場合は、それまでの適用分だけコミットされた状態で結果に含めて返す
  // (呼び出し側は resolutions を足して衝突が無くなるまで呼び直す)
  Future<ChangeRequestApplyResult> applyChangeRequests(
    String storeId,
    String weekStartDate,
    List<ChangeRequestResolution> resolutions,
  ) async {
    final service = ref.read(shiftTableServiceProvider);
    final result = await service.applyChangeRequests(
        storeId, weekStartDate, resolutions);
    ref.invalidate(
        shiftTableProvider(storeId: storeId, weekStartDate: weekStartDate));
    ref.invalidate(shiftChangeRequestsProvider(
        storeId: storeId, weekStartDate: weekStartDate));
    return result;
  }

  // 修正依頼を1件削除する (マネージャー専用。衝突で見送られ、対応不要になった依頼を
  // 手動で消す用)
  Future<void> deleteChangeRequest(
      String storeId, String weekStartDate, String requestId) async {
    final service = ref.read(shiftTableServiceProvider);
    await service.deleteChangeRequest(storeId, weekStartDate, requestId);
    ref.invalidate(shiftChangeRequestsProvider(
        storeId: storeId, weekStartDate: weekStartDate));
  }
}
