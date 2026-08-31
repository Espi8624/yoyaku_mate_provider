// 勤務可能時間帯の定義
class TimeBlock {
  static const String morning = 'MORNING';
  static const String afternoon = 'AFTERNOON';
  static const String evening = 'EVENING';

  // 選択UIで使う順序付きリスト (夜間は選択肢から除外。evening自体は
  // 過去データ互換のため定数として残す)
  static const List<String> values = [morning, afternoon];

  static String label(String block) {
    switch (block) {
      case morning:
        return '午前';
      case afternoon:
        return '午後';
      case evening:
        return '夜間';
      default:
        return block;
    }
  }

  // 各ブロックの基準時間帯 (0〜24時、時間単位)
  // 夜間を選択肢から除外したため、旧夜間帯(18〜24時)は午後に統合
  // (evening は values に含まれないため、ここでの定義は不要)
  static const Map<String, List<int>> _referenceHourRange = {
    morning: [0, 12],
    afternoon: [12, 24],
  };

  // 指定された営業時間(start〜end, "HH:MM"形式)とこのブロックの基準時間帯が
  // 少しでも重なっていれば選択可能(true)とみなす
  // 定休日(isClosed)は常にfalse、24時間営業(is24Hours)は常にtrue
  // start/endが未設定・不正な場合は制限をかけない(fail-open)ためtrueを返す
  static bool overlapsBusinessHours(
    String block, {
    bool is24Hours = false,
    bool isClosed = false,
    String? start,
    String? end,
  }) {
    if (isClosed) return false;
    if (is24Hours) return true;

    final range = _referenceHourRange[block];
    if (range == null) return true;

    final startMinutes = _parseToMinutes(start);
    final endMinutes = _parseToMinutes(end);
    if (startMinutes == null || endMinutes == null) {
      // 営業時間データが無い場合は制限しない
      return true;
    }
    if (startMinutes >= endMinutes) {
      return true;
    }

    final blockStartMinutes = range[0] * 60;
    final blockEndMinutes = range[1] * 60;
    return startMinutes < blockEndMinutes && endMinutes > blockStartMinutes;
  }

  static int? _parseToMinutes(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}

// 曜日キーの定義 (サーバー側のフィールド名と一致させる)
class Weekday {
  static const String monday = 'monday';
  static const String tuesday = 'tuesday';
  static const String wednesday = 'wednesday';
  static const String thursday = 'thursday';
  static const String friday = 'friday';
  static const String saturday = 'saturday';
  static const String sunday = 'sunday';

  static const List<String> values = [
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  ];

  static const List<String> labels = ['月', '火', '水', '木', '金', '土', '日'];
}
