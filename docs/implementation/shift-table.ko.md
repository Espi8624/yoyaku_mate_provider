# 구현 상세서: 시프트표 (Shift Table)

본 문서는 `yoyaku_mate_provider`에 구현된 시프트표(Shift Table) 기능의 기술적 설계 및 구현 상세를 설명합니다.

> 작성일: 2026-09-01
> 관련 문서: [시프트표 기능 명세서](../features/shift-table.ko.md), [서버 측 구현 상세서](../../../yoyaku_mate_server/docs/implementation/shift-table.ko.md)

---

## 1. 모델 (`lib/models/shift_table.dart`)

```dart
class Shift {
  final String id;
  final String staffId;
  final String day;       // Weekday 상수 키 (monday..sunday)
  final String startTime; // "HH:MM"
  final String endTime;   // "HH:MM"
}

class ShiftTable {
  final String id;
  final String storeId;
  final String weekStartDate; // 해당 주의 월요일 "YYYY-MM-DD"
  final List<Shift> shifts;
}
```

서버의 BSON/JSON 필드명과 그대로 일치시켜 변환 처리를 불필요하게 했다(`staff_availability` 구현과 동일한 방침).

---

## 2. 서비스 계층 (`lib/services/shift_table_service.dart`)

`store_settings_service.dart`와 동일한 `_getIdToken()` 패턴을 따른다. 서버 응답 봉투 `{ "status": "success", "data": ... }`에서 `data`를 꺼내는 부분도 기존 `fetchStoreStaff`와 공통이다.

```dart
Future<ShiftTable?> fetchShiftTable(String storeId, String weekStartDate)
Future<void> createShiftTable(String storeId, String weekStartDate)
Future<void> addShift(String storeId, String weekStartDate, {required staffId, required day, required startTime, required endTime})
Future<void> updateShift(String storeId, String weekStartDate, String shiftId, {...})
Future<void> deleteShift(String storeId, String weekStartDate, String shiftId)
```

`fetchShiftTable`은 HTTP `404`를 예외로 던지지 않고 `null`로 반환하는 것이 특징이며, 호출측(Riverpod provider)은 이를 그대로 "시프트표 미생성" 상태로 취급한다. `lib/providers/session_providers.dart`에 `shiftTableServiceProvider`로 등록.

---

## 3. Riverpod 프로바이더 (`lib/pages/staff_management_page/shift_table_providers.dart`)

`staff_management_providers.dart`와 동일한 설계:

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

`ShiftActions`는 상태를 갖지 않는 액션 전용 Notifier이며, 각 메서드는 성공 시 `shiftTableProvider(storeId:, weekStartDate:)`를 invalidate하여 선언적으로 재조회시킨다. `storeId` + `weekStartDate` family 키 덕분에 주를 전환할 때마다 별도의 조회 결과가 캐시된다.

---

## 4. 화면 전환: PageView를 통한 스와이프 (`staff_management_screen.dart`)

`StaffManagementScreen`은 `StatelessWidget`에서 `HookWidget`으로 변경했고, `usePageController()`로 페이지 컨트롤러를 생성한다.

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

`sign_up_page.dart`의 `PageView`와 달리 `NeverScrollableScrollPhysics`를 지정하지 않았기 때문에 기본 스와이프 동작으로 페이지가 전환된다. AppBar 타이틀과 화면 하단의 점 인디케이터는 `currentPage`(`useState`)를 참조해 다시 그려진다.

---

## 5. 시프트표 그리드 레이아웃 (`widgets/shift_table_view.dart`)

Outlook/Teams의 주간 화면을 재현하기 위해 다음 구성을 채택했다.

### 5.1 시간 범위 산출

```dart
({int startHour, int endHour}) _computeHourRange(StoreSettings? settings, List<Shift> shifts)
```

매장 영업시간(`storeSettings.operatingHours`, `Weekday.values`의 7요일)의 최소 시작·최대 종료 시각과, 기존 시프트의 최소 시작·최대 종료 시각을 모두 훑어 더 넓은 범위를 그리드 표시 범위로 채택한다. 정보가 없으면 9~21시를 기본값으로 사용한다. `is24Hours`가 true이면 0~24시.

### 5.2 세로 스크롤 동기화

시간 라벨 열(왼쪽 고정)과 그리드 본체(오른쪽, 가로 스크롤 가능)의 세로 스크롤을 동기화하기 위해, **2개의 독립된 `ScrollController`를 쓰지 않고** 단일 `verticalController`를 그리드 쪽 `SingleChildScrollView`에만 연결하고, 시간 라벨 열은 `AnimatedBuilder` + `Transform.translate`로 그 오프셋을 따라가게 하는 방식을 채택했다.

```dart
AnimatedBuilder(
  animation: verticalController,
  builder: (context, _) {
    final offset = verticalController.hasClients ? verticalController.offset : 0.0;
    return Transform.translate(offset: Offset(0, -offset), child: _TimeLabelsColumn(...));
  },
)
```

2개의 `ScrollController`를 리스너로 상호 동기화하는 일반적인 패턴보다 단순하며, 드래그 조작으로 인한 무한 루프 방지용 플래그 관리도 불필요하다.

### 5.3 시프트 블록 배치

`_DayGrid`는 요일별로 `Stack`을 가지며, 각 시프트를 `Positioned`로 배치한다.

```dart
top = ((startMinutes - gridStartMinutes) / 60.0) * _hourHeight
height = ((endMinutes - startMinutes) / 60.0) * _hourHeight
```

색상은 `staffColors` 맵(`AppColors.shiftBlockPalette`를 스태프 인덱스로 순환 배정)을 참조한다.

### 5.4 추가/편집 다이얼로그

`_ShiftFormDialog`는 스태프 선택·요일 선택 `DropdownButtonFormField`와, `showTimePicker`를 통한 시작/종료 시각 선택으로 구성된다. 편집 모드(`initialShift`가 null이 아닌 경우)에만 "삭제" 버튼을 표시하며, 결과는 `_ShiftFormResult`(`delete: true/false`)로 호출측에 반환된다. 호출측(`_ShiftGridBody`)이 `delete` 플래그를 보고 `addShift`/`updateShift`/`deleteShift` 중 무엇을 호출할지 분기한다.

---

## 6. 색상 팔레트 (`lib/constants/app_colors.dart`)

```dart
static const List<Color> shiftBlockPalette = [
  Color(0xFF5B8DEF), Color(0xFF4CAF93), Color(0xFFB080E0),
  Color(0xFFE0954F), Color(0xFFE0709E), Color(0xFF4FADC7),
];
```

코딩 규칙에 따라 시프트 블록 색상은 `app_colors.dart`에 정의된 값만 사용한다. 승인된 스태프 목록 내 인덱스를 `% shiftBlockPalette.length`로 순환 배정하여 담당자별 시각적 구분을 결정론적으로 수행한다.
