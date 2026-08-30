# 구현 상세서: 스태프 근무 가능 시간 (Staff Availability)

본 문서는 `yoyaku_mate_provider`에 구현된 스태프 근무 가능 시간(Staff Availability) 기능의 기술적 설계 및 구현 상세를 설명합니다.

> 작성일: 2026-08-30  
> 관련 문서: [스태프 근무 가능 시간 기능 사양서](../features/staff-availability.ko.md), [서버 측 구현 상세서](../../../yoyaku_mate_server/docs/implementation/staff-availability.ko.md)

---

## 1. 상수 (`lib/constants/time_block.dart`)

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

서버 측 BSON/JSON 필드명(`monday` 등)과 그대로 일치시켜, 클라이언트·서버 간 변환 처리를 불필요하게 만들었다.

---

## 2. 2단 구성의 다이얼로그

용도에 따라 2종류의 다이얼로그를 구분해서 사용한다.

| 다이얼로그 | 대상 | 용도 |
|---|---|---|
| `AvailabilityDialog` (`dialogs/availability_dialog.dart`) | 본인 (개인 프로필 화면) | 7개 요일을 한 번에 일괄 편집. 기존 `BusinessHoursDialog`(영업시간 설정)와 동일한 레이아웃 패턴을 재사용 |
| `DayAvailabilityDialog` (`dialogs/day_availability_dialog.dart`) | 매니저 (스태프 관리 화면) | 요일 뱃지 하나를 탭했을 때, 그 요일 하루치만 편집하는 경량 다이얼로그 |

둘 다 공통 `BaseDialog`를 기반으로 하며, 시간대 선택에는 `ChoiceChip`(`TimeBlock.values` 순회)을 사용한다.

---

## 3. ViewModel 계층

### 3.1 본인용 (`profile_screen_viewmodel.dart`)

```dart
Future<Map<String, dynamic>> fetchMyAvailability()
Future<bool> updateMyAvailability(Map<String, List<String>> availability)
```

기존 `storeId` getter(`_storeProfile?.id`)를 재사용하고, `joinStore` 등과 동일한 try/catch + `_errorMessage`/`_successMessage` 패턴을 따른다.

### 3.2 매니저용 (`staff_management_viewmodel.dart`)

```dart
Future<bool> updateStoreStaffAvailability(
    String storeId, String staffId, Map<String, List<String>> availability)
```

기존 `updateStoreStaffStatus` / `updateStoreStaffPermissions`와 동일하게, 업데이트 후 `fetchStoreStaff(storeId, silent: true)`를 호출해 목록을 조용히 재조회하여 다른 변경 사항과의 정합성을 유지한다.

---

## 4. 요일 단위 부분 업데이트 로직 (`staff_management_view.dart`)

서버 측 `PATCH .../availability` API는 항상 한 주 전체의 `availability` 객체를 요구하므로, 매니저가 특정 요일 하나만 편집한 경우에도 클라이언트에서 나머지 6개 요일의 기존 값을 유지한 채 병합한 뒤 전송한다.

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

## 5. 스태프 카드의 개폐 상태 관리

`_StaffCardState`는 "권한설정"과 "근무 가능일"을 **독립된 2개의 boolean state**로 관리하며, 서로의 개폐 상태에 영향을 주지 않는다.

```dart
bool _isExpanded = false;             // 권한설정 개폐 상태
bool _isAvailabilityExpanded = false; // 근무 가능일 개폐 상태
```

`_AvailabilitySummary` 위젯은 요일별 탭 동작을 부모(`_StaffCardState`)에 위임하는 콜백 방식을 채택했다.

```dart
class _AvailabilitySummary extends StatelessWidget {
  final Map<String, dynamic> availability;
  final void Function(String day, String dayLabel) onDayTap;
  ...
}
```

요일 뱃지는 `InkWell` + `CircleBorder`로 56×56 크기의 원형 탭 영역을 확보하며, 근무 가능한 요일은 `AppColors.accentPrimary` 테두리·배경, 불가능한 요일은 회색으로 표시한다.
