// スタッフ管理画面の状態管理 (Riverpod)
//
// Provider(MVVM)からの移行パイロット。
// - API取得結果は FutureProvider(staffListProvider) で宣言的に扱う (AsyncValue)
// - 更新系アクションは状態を持たない NotifierProvider(staffActionsProvider) に集約し、
//   成功時は staffListProvider を invalidate して再取得させる (楽観的ローカル更新は行わない。
//   Riverpodは invalidate 後も直前のデータを保持したままバックグラウンド再取得するため、
//   画面のちらつきは発生しない)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yoyaku_mate_provider/providers/session_providers.dart';

part 'staff_management_providers.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> staffList(
  Ref ref, {
  required String storeId,
}) async {
  final service = ref.watch(profileServiceProvider);
  final staff = await service.fetchStoreStaff(storeId);
  return staff.cast<Map<String, dynamic>>();
}

@riverpod
class StaffActions extends _$StaffActions {
  // 状態を持たないアクション専用Notifier
  @override
  void build() {}

  Future<void> updateStatus(
      String storeId, String staffId, String status) async {
    final service = ref.read(profileServiceProvider);
    await service.updateStoreStaffStatus(storeId, staffId, status);
    ref.invalidate(staffListProvider(storeId: storeId));
  }

  Future<void> updatePermissions(
      String storeId, String staffId, List<String> permissions) async {
    final service = ref.read(profileServiceProvider);
    await service.updateStoreStaffPermissions(storeId, staffId, permissions);
    ref.invalidate(staffListProvider(storeId: storeId));
  }

  Future<void> updateAvailability(String storeId, String staffId,
      Map<String, List<String>> availability) async {
    final service = ref.read(profileServiceProvider);
    await service.updateStoreStaffAvailability(storeId, staffId, availability);
    ref.invalidate(staffListProvider(storeId: storeId));
  }
}
