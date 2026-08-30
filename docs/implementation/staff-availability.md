# 実装詳細書: スタッフ勤務可能時間 (Staff Availability)

本文書は、`yoyaku_mate_provider` に実装されたスタッフ勤務可能時間 (Staff Availability) 機能の技術的設計および実装詳細を説明します。

> 作成日: 2026-08-30  
> 関連文書: [スタッフ勤務可能時間機能仕様書](../features/staff-availability.md)、[サーバー側実装詳細書](../../../yoyaku_mate_server/docs/implementation/staff-availability.md)

---

## 1. 定数 (`lib/constants/time_block.dart`)

```dart
class TimeBlock {
  static const String morning = 'MORNING';
  static const String afternoon = 'AFTERNOON';
  static const String evening = 'EVENING';
  static const List<String> values = [morning, afternoon, evening];
}

class Weekday {
  static const List<String> values = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday',
  ];
  static const List<String> labels = ['月', '火', '水', '木', '金', '土', '日'];
}
```

サーバー側の BSON/JSON フィールド名 (`monday` 等) とそのまま一致させ、クライアント・サーバー間の変換処理を不要にしている。

---

## 2. ダイアログの二段構成

用途に応じて2種類のダイアログを使い分ける。

| ダイアログ | 対象 | 用途 |
|---|---|---|
| `AvailabilityDialog` (`dialogs/availability_dialog.dart`) | 本人 (個人プロフィール画面) | 7曜日をまとめて一括編集。既存の `BusinessHoursDialog` (営業時間設定) と同一のレイアウトパターンを踏襲 |
| `DayAvailabilityDialog` (`dialogs/day_availability_dialog.dart`) | マネージャー (スタッフ管理画面) | 曜日バッジ1つをタップした際に、その曜日1日分だけを編集する軽量ダイアログ |

いずれも共通の `BaseDialog` を土台にしており、時間帯選択には `ChoiceChip` (`TimeBlock.values` をループ) を使用する。

---

## 3. ViewModel 層

### 3.1 本人用 (`profile_screen_viewmodel.dart`)

```dart
Future<Map<String, dynamic>> fetchMyAvailability()
Future<bool> updateMyAvailability(Map<String, List<String>> availability)
```

既存の `storeId` ゲッター (`_storeProfile?.id`) を再利用し、`joinStore` などと同一の try/catch + `_errorMessage`/`_successMessage` パターンに従う。

### 3.2 マネージャー用 (`staff_management_viewmodel.dart`)

```dart
Future<bool> updateStoreStaffAvailability(
    String storeId, String staffId, Map<String, List<String>> availability)
```

既存の `updateStoreStaffStatus` / `updateStoreStaffPermissions` と同じく、更新後に `fetchStoreStaff(storeId, silent: true)` を呼び出してサイレントに一覧を再取得し、他の変更内容との整合性を保つ。

---

## 4. 曜日単位の部分更新ロジック (`staff_management_view.dart`)

サーバー側の `PATCH .../availability` API は常に週全体の `availability` オブジェクトを要求するため、マネージャーが特定の1曜日だけを編集した場合でも、クライアント側で他の6曜日の既存値を維持したままマージしてから送信する。

```dart
Future<void> _showDayAvailabilityDialog(
    BuildContext context, String day, String dayLabel) async {
  final availability = widget.staff['availability'] as Map<String, dynamic>? ?? {};
  final currentBlocks = (availability[day] as List<dynamic>?)
          ?.map((e) => e.toString()).toList() ?? <String>[];

  final result = await showDialog<List<String>>(
    context: context,
    builder: (_) => DayAvailabilityDialog(dayLabel: dayLabel, initialBlocks: currentBlocks),
  );

  if (result != null) {
    final updatedAvailability = {
      for (final d in Weekday.values)
        d: (availability[d] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[],
    };
    updatedAvailability[day] = result;

    await widget.vm.updateStoreStaffAvailability(widget.storeId, widget.staff['_id'], updatedAvailability);
  }
}
```

---

## 5. スタッフ管理カードの開閉状態管理

`_StaffCardState` は「権限設定」と「勤務可能日」を **独立した2つの boolean state** で管理しており、互いの開閉状態に影響しない。

```dart
bool _isExpanded = false;             // 権限設定の開閉状態
bool _isAvailabilityExpanded = false; // 勤務可能日の開閉状態
```

`_AvailabilitySummary` ウィジェットは、曜日ごとのタップ操作を親 (`_StaffCardState`) に委譲するコールバック方式を採用している。

```dart
class _AvailabilitySummary extends StatelessWidget {
  final Map<String, dynamic> availability;
  final void Function(String day, String dayLabel) onDayTap;
  ...
}
```

曜日バッジは `InkWell` + `CircleBorder` で56×56の円形タップ領域を確保し、勤務可能な曜日は `AppColors.accentPrimary` の枠線・背景、不可の曜日はグレーで表示する。
