# 実装詳細書: シフト表 (Shift Table)

本文書は、`yoyaku_mate_provider` に実装されたシフト表 (Shift Table) 機能の技術的設計および実装詳細を説明します。

> 作成日: 2026-09-01
> 関連文書: [シフト表機能仕様書](../features/shift-table.md)、[サーバー側実装詳細書](../../../yoyaku_mate_server/docs/implementation/shift-table.md)

---

## 1. モデル (`lib/models/shift_table.dart`)

```dart
class Shift {
  final String id;
  final String staffId;
  final String day;       // Weekday定数のキー (monday..sunday)
  final String startTime; // "HH:MM"
  final String endTime;   // "HH:MM"
}

class ShiftTable {
  final String id;
  final String storeId;
  final String weekStartDate; // その週の月曜日 "YYYY-MM-DD"
  final List<Shift> shifts;
}
```

サーバーの BSON/JSON フィールド名とそのまま一致させ、変換処理を不要にしている(`staff_availability` 実装と同じ方針)。

---

## 2. サービス層 (`lib/services/shift_table_service.dart`)

`store_settings_service.dart` と同じ `_getIdToken()` パターンに従う。サーバーのレスポンス封筒 `{ "status": "success", "data": ... }` から `data` を取り出す点も既存の `fetchStoreStaff` と共通。

```dart
Future<ShiftTable?> fetchShiftTable(String storeId, String weekStartDate)
Future<void> createShiftTable(String storeId, String weekStartDate)
Future<void> addShift(String storeId, String weekStartDate, {required staffId, required day, required startTime, required endTime})
Future<void> updateShift(String storeId, String weekStartDate, String shiftId, {...})
Future<void> deleteShift(String storeId, String weekStartDate, String shiftId)
```

`fetchShiftTable` は HTTP `404` を例外にせず `null` として返す点が特徴的で、呼び出し側 (Riverpod provider) はこれをそのまま「シフト表未作成」状態として扱う。`lib/providers/session_providers.dart` に `shiftTableServiceProvider` として登録。

---

## 3. Riverpod プロバイダー (`lib/pages/staff_management_page/shift_table_providers.dart`)

`staff_management_providers.dart` と同じ設計:

```dart
@riverpod
Future<ShiftTable?> shiftTable(Ref ref, {required String storeId, required String weekStartDate})

@riverpod
class ShiftActions extends _$ShiftActions {
  Future<void> createTable(...)
  Future<void> addShift(...)
  Future<void> updateShift(...)
  Future<void> deleteShift(...)
}
```

`ShiftActions` は状態を持たないアクション専用 Notifier で、各メソッドは成功時に `shiftTableProvider(storeId:, weekStartDate:)` を invalidate して宣言的に再取得させる。`storeId` + `weekStartDate` の family キーにより、週を切り替えるたびに別々の取得結果がキャッシュされる。

---

## 4. 画面遷移: PageView によるスワイプ (`staff_management_screen.dart`)

`StaffManagementScreen` は `StatelessWidget` から `HookWidget` に変更し、`usePageController()` でページコントローラーを生成。

```dart
final pageController = usePageController();
final currentPage = useState(0);
...
PageView(
  controller: pageController,
  onPageChanged: (index) => currentPage.value = index,
  children: [
    StaffManagementView(storeId: storeId),
    ShiftTableView(storeId: storeId),
  ],
)
```

`sign_up_page.dart` の `PageView` とは異なり `NeverScrollableScrollPhysics` を指定していないため、デフォルトのスワイプ操作でページが切り替わる。AppBar タイトルとページ下部のドットインジケーターは `currentPage`(`useState`)を参照して再描画される。

---

## 5. シフト表グリッドのレイアウト (`widgets/shift_table_view.dart`)

Outlook/Teams の週間ビューを再現するため、以下の構成を採用した。

### 5.1 時間範囲の算出

```dart
({int startHour, int endHour}) _computeHourRange(StoreSettings? settings, List<Shift> shifts)
```

店舗の営業時間 (`storeSettings.operatingHours`、`Weekday.values` の7曜日) の最小開始・最大終了時刻と、既存シフトの最小開始・最大終了時刻の両方を走査し、より広い範囲をグリッドの表示範囲として採用する。情報が無い場合は 9〜21時をデフォルトとする。`is24Hours` が true の場合は 0〜24時。

### 5.2 縦スクロール同期

時間ラベル列(左側固定)とグリッド本体(右側、横スクロール可能)の縦スクロールを同期させるため、**2つの独立した `ScrollController` を使わず**、単一の `verticalController` をグリッド側の `SingleChildScrollView` にのみ接続し、時間ラベル列は `AnimatedBuilder` + `Transform.translate` でそのオフセットを追従させる方式を採用した。

```dart
AnimatedBuilder(
  animation: verticalController,
  builder: (context, _) {
    final offset = verticalController.hasClients ? verticalController.offset : 0.0;
    return Transform.translate(offset: Offset(0, -offset), child: _TimeLabelsColumn(...));
  },
)
```

2つの `ScrollController` をリスナーで相互同期させる一般的なパターンより単純で、ドラッグ操作による無限ループ回避のためのフラグ管理も不要になる。

### 5.3 シフトブロックの配置

`_DayGrid` は曜日ごとに `Stack` を持ち、各シフトを `Positioned` で配置する。

```dart
top = ((startMinutes - gridStartMinutes) / 60.0) * _hourHeight
height = ((endMinutes - startMinutes) / 60.0) * _hourHeight
```

色は `staffColors` マップ (`AppColors.shiftBlockPalette` をスタッフインデックスで循環割り当て) を参照。

### 5.4 追加/編集ダイアログ

`_ShiftFormDialog` はスタッフ選択・曜日選択の `DropdownButtonFormField` と、`showTimePicker` による開始/終了時刻選択で構成される。編集モード (`initialShift` が非null) の場合のみ「削除」ボタンを表示し、結果は `_ShiftFormResult` (`delete: true/false`) として呼び出し元に返す。呼び出し側 (`_ShiftGridBody`) が `delete` フラグを見て `addShift`/`updateShift`/`deleteShift` のいずれを呼ぶか分岐する。

---

## 6. 色パレット (`lib/constants/app_colors.dart`)

```dart
static const List<Color> shiftBlockPalette = [
  Color(0xFF5B8DEF), Color(0xFF4CAF93), Color(0xFFB080E0),
  Color(0xFFE0954F), Color(0xFFE0709E), Color(0xFF4FADC7),
];
```

コーディング規約により、シフトブロックの色は `app_colors.dart` に定義済みの値のみを使用する。承認済みスタッフのリスト内インデックスを `% shiftBlockPalette.length` で循環割り当てし、担当者ごとの視覚的な区別を決定論的に行う。
