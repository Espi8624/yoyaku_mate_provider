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
  final String status; // 'pending' | 'resolved'
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

  bool get isPending => status == 'pending';

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
