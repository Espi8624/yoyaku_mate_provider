// 勤務可能時間帯の定義
class TimeBlock {
  static const String morning = 'MORNING';
  static const String afternoon = 'AFTERNOON';
  static const String evening = 'EVENING';

  // 選択UIで使う順序付きリスト
  static const List<String> values = [morning, afternoon, evening];

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
