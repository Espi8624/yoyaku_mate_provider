// 店舗の週単位シフト表モデル

// 週内の1件の勤務シフト
class Shift {
  final String id;
  final String staffId;
  final String day; // Weekday定数のキー (monday..sunday)
  final String startTime; // "HH:MM"
  final String endTime; // "HH:MM"

  Shift({
    required this.id,
    required this.staffId,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      day: json['day'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'staff_id': staffId,
        'day': day,
        'start_time': startTime,
        'end_time': endTime,
      };
}

// 店舗の週単位シフト表 (マネージャーが明示的に作成するまで存在しない)
//
// サーバー側は下書きと確定版を別々に持つが、shifts には「自分が見るべき版」が入って返る
// (マネージャーには編集中の下書き、スタッフには確定版)。そのため描画側は両者を区別しなくてよい
class ShiftTable {
  final String id;
  final String storeId;
  final String weekStartDate; // その週の月曜日 "YYYY-MM-DD"
  final List<Shift> shifts;

  // 下書きに未確定の変更が残っているか。マネージャー向けのレスポンスにのみ含まれ、
  // 「確定」ボタンの活性/非活性の判断に使う (スタッフには常に false)
  final bool hasUnpublishedChanges;

  // 最後にスタッフへ公開した日時。null は一度も確定していないことを表す
  final DateTime? publishedAt;

  ShiftTable({
    required this.id,
    required this.storeId,
    required this.weekStartDate,
    required this.shifts,
    this.hasUnpublishedChanges = false,
    this.publishedAt,
  });

  // 作ったばかりで中身が空、かつ一度も確定していない状態。
  // サーバーは「一度も確定していない」を未確定変更として扱うため、これを区別しないと
  // 空の表にまで確定/破棄の導線が出てしまう
  bool get isUntouchedNewTable => publishedAt == null && shifts.isEmpty;

  // 確定または破棄の対象になる下書きがあるか。
  // 「確定して公開」ボタンと「下書きを破棄」ボタンの表示条件を揃えるために使う
  bool get hasDraftToReview => hasUnpublishedChanges && !isUntouchedNewTable;

  factory ShiftTable.fromJson(Map<String, dynamic> json) {
    return ShiftTable(
      id: json['_id'] ?? '',
      storeId: json['store_id'] ?? '',
      weekStartDate: json['week_start_date'] ?? '',
      shifts: (json['shifts'] as List<dynamic>?)
              ?.map((e) => Shift.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Shift>[],
      hasUnpublishedChanges: json['has_unpublished_changes'] ?? false,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }
}
