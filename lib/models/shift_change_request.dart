// シフトブロックに対する修正依頼 (スタッフが自分の割当ブロックをタップして、
// 「現在の割当(From)→希望する割当(To)」を送る。スタッフ→マネージャー)
//
// From/To はシフト表の Shift と同じ day/start_time/end_time 形式で保持する。
// 将来「依頼内容をそのままシフト編集に反映する」機能を追加する予定のため、
// その時にそのまま流用できるようあえて形式を統一している
class ShiftChangeRequest {
  final String id;
  final String staffId;
  final String staffName;
  final String targetShiftId;
  final String fromDay;
  final String fromStartTime;
  final String fromEndTime;
  final String toDay;
  final String toStartTime;
  final String toEndTime;
  // 'pending' | 'applied' | 'resolved'
  // applied はマネージャーが下書きへ反映済みだがまだ確定していない中間状態で、
  // マネージャーにしか届かない (スタッフ向けレスポンスでは pending に伏せられる)
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  ShiftChangeRequest({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.targetShiftId,
    required this.fromDay,
    required this.fromStartTime,
    required this.fromEndTime,
    required this.toDay,
    required this.toStartTime,
    required this.toEndTime,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  // まだマネージャーが手を付けていない依頼 (適用処理の対象になるのはこれだけ)
  bool get isPending => status == 'pending';

  // 下書きへ反映済み・未確定。確定すると resolved に進む
  bool get isApplied => status == 'applied';

  // 確定済みでスタッフにも「対応済み」として見えている
  bool get isResolved => status == 'resolved';

  factory ShiftChangeRequest.fromJson(Map<String, dynamic> json) {
    return ShiftChangeRequest(
      id: json['_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      staffName: json['staff_name'] ?? '不明',
      targetShiftId: json['target_shift_id'] ?? '',
      fromDay: json['from_day'] ?? '',
      fromStartTime: json['from_start_time'] ?? '',
      fromEndTime: json['from_end_time'] ?? '',
      toDay: json['to_day'] ?? '',
      toStartTime: json['to_start_time'] ?? '',
      toEndTime: json['to_end_time'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
    );
  }
}

// 修正依頼の一括適用(ApplyShiftChangeRequestsHandler)で、マネージャーが衝突1件に
// 下した判断。サーバーの changeRequestResolution とフィールドを合わせている
class ChangeRequestResolution {
  static const actionPrioritize = 'prioritize';
  static const actionSwap = 'swap';
  static const actionConfirmOverlap = 'confirm_overlap';
  static const actionSkip = 'skip';

  final String requestId;
  final String action;
  final String? targetStaffId;

  ChangeRequestResolution({
    required this.requestId,
    required this.action,
    this.targetStaffId,
  });

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'action': action,
        if (targetStaffId != null) 'target_staff_id': targetStaffId,
      };
}

// 衝突ダイアログに並べる選択肢1件(名前ボタン)
class ChangeRequestCandidate {
  final String staffId;
  final String staffName;
  // requestId は依頼同士の衝突(requestConflict)でのみ入る(この候補自身の依頼ID)
  final String? requestId;

  ChangeRequestCandidate({
    required this.staffId,
    required this.staffName,
    this.requestId,
  });

  factory ChangeRequestCandidate.fromJson(Map<String, dynamic> json) {
    return ChangeRequestCandidate(
      staffId: json['staff_id'] ?? '',
      staffName: json['staff_name'] ?? '不明',
      requestId: json['request_id'],
    );
  }
}

// マネージャーの判断待ちの衝突1件
class ChangeRequestConflict {
  static const typeRequestConflict = 'request_conflict';
  static const typeCapacity = 'capacity_conflict';
  static const typeSelfOverlap = 'self_overlap_conflict';

  final String type;
  final String requestId;
  final String staffName;
  final String toDay;
  final String toStartTime;
  final String toEndTime;
  final List<ChangeRequestCandidate> candidates;

  ChangeRequestConflict({
    required this.type,
    required this.requestId,
    required this.staffName,
    required this.toDay,
    required this.toStartTime,
    required this.toEndTime,
    required this.candidates,
  });

  factory ChangeRequestConflict.fromJson(Map<String, dynamic> json) {
    return ChangeRequestConflict(
      type: json['type'] ?? '',
      requestId: json['request_id'] ?? '',
      staffName: json['staff_name'] ?? '不明',
      toDay: json['to_day'] ?? '',
      toStartTime: json['to_start_time'] ?? '',
      toEndTime: json['to_end_time'] ?? '',
      candidates: (json['candidates'] as List<dynamic>? ?? [])
          .map((e) => ChangeRequestCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// 一括適用1回の呼び出し結果。conflict が null なら全て処理完了(done=true)
class ChangeRequestApplyResult {
  final int appliedCount;

  // 本人が同じ枠へ出し直したため、古い依頼を解決済みにした件数
  final int supersededCount;

  // 依頼元のシフトが既に無く適用できないため、解決済みにした件数。
  // 「既に処理済み」とは限らず、マネージャーがそのシフトを削除・変更した場合も含む
  final int skippedStaleCount;

  final bool done;
  final ChangeRequestConflict? conflict;

  ChangeRequestApplyResult({
    required this.appliedCount,
    required this.supersededCount,
    required this.skippedStaleCount,
    required this.done,
    this.conflict,
  });

  factory ChangeRequestApplyResult.fromJson(Map<String, dynamic> json) {
    return ChangeRequestApplyResult(
      appliedCount: json['applied_count'] ?? 0,
      supersededCount: json['superseded_count'] ?? 0,
      skippedStaleCount: json['skipped_stale_count'] ?? 0,
      done: json['done'] ?? true,
      conflict: json['conflict'] != null
          ? ChangeRequestConflict.fromJson(json['conflict'] as Map<String, dynamic>)
          : null,
    );
  }
}
