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
class ShiftTable {
  final String id;
  final String storeId;
  final String weekStartDate; // その週の月曜日 "YYYY-MM-DD"
  final List<Shift> shifts;

  ShiftTable({
    required this.id,
    required this.storeId,
    required this.weekStartDate,
    required this.shifts,
  });

  factory ShiftTable.fromJson(Map<String, dynamic> json) {
    return ShiftTable(
      id: json['_id'] ?? '',
      storeId: json['store_id'] ?? '',
      weekStartDate: json['week_start_date'] ?? '',
      shifts: (json['shifts'] as List<dynamic>?)
              ?.map((e) => Shift.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Shift>[],
    );
  }
}
