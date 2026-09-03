# 시프트표 (Shift Table)

> 최종 수정: 2026-09-01
> 관련 파일: [`lib/pages/staff_management_page/staff_management_screen.dart`](../../lib/pages/staff_management_page/staff_management_screen.dart), [`lib/pages/staff_management_page/widgets/shift_table_view.dart`](../../lib/pages/staff_management_page/widgets/shift_table_view.dart), [`lib/pages/staff_management_page/shift_table_providers.dart`](../../lib/pages/staff_management_page/shift_table_providers.dart)

## 개요

스태프 관리 화면에, 매장 매니저가 주 단위 시프트(누가 언제 근무하는지)를 짤 수 있는 "시프트표" 페이지를 추가한 기능입니다. Outlook / Microsoft Teams의 주간 캘린더 화면을 참고한 요일×시간 그리드 UI를 채택했습니다.

---

## 1. 화면 구성 (2페이지 + 스와이프)

스태프 관리 화면(`StaffManagementScreen`)은 `PageView`를 통한 2페이지 구성이 되었습니다.

* **페이지1**: 기존 스태프 관리(스태프 목록·승인/권한·근무가능시간) — `StaffManagementView`
* **페이지2**: 시프트표 — `ShiftTableView`

페이지1을 **오른쪽으로 스와이프**하면 페이지2(시프트표)로 전환됩니다. 화면 하단에는 현재 페이지를 나타내는 점 인디케이터가 있고, AppBar 타이틀도 페이지에 따라 "스태프 관리"/"시프트표"로 전환됩니다.

---

## 2. 시프트표 페이지 구성

* **주 선택 헤더**: `‹ 9/1(월) - 9/7(일) ›` 형식으로 표시되며, 앞뒤 화살표로 주를 이동할 수 있습니다.
* **미생성 주**: 해당 주에 시프트표가 아직 생성되지 않은 경우 안내 문구만 표시됩니다. 매니저인 경우에만 "시프트표 생성" 버튼이 표시되며, 탭하면 빈 시프트표가 생성됩니다.
* **생성된 주**: 요일(월~일, 가로 방향) × 시간(세로 방향, 매장 영업시간 기준 자동 산출) 그리드가 표시됩니다. 각 시프트는 스태프별로 색상이 구분된 블록으로, 시작~종료 시각에 대응하는 위치·높이로 그려집니다.

### 권한에 따른 차이

| 조작 | 매니저 | 스태프 |
|---|---|---|
| 시프트표 열람 | ○ | ○ (승인된 스태프만) |
| 시프트표 생성 | ○ | × |
| 시프트 추가/수정/삭제 | ○ | × |

매니저에게는 화면 우측 상단에 "시프트 추가" 버튼이 표시되며, 승인된 스태프·요일·시작/종료 시각을 선택하는 다이얼로그로 시프트를 추가할 수 있습니다. 그리드 위의 시프트 블록을 탭하면 같은 다이얼로그가 편집 모드(삭제 버튼 포함)로 열립니다.

---

## 3. UI 설계 포인트

* 시프트 블록 색상은 `AppColors.shiftBlockPalette`의 6가지 색을 스태프 인덱스로 순환 배정하여, 누구의 시프트인지 한눈에 구분할 수 있게 했습니다.
* 그리드의 시간 범위는 매장 설정의 영업시간(`storeSettingsProvider`)과 등록된 시프트 시각 양쪽을 모두 반영해 자동 산출되며, 영업시간 밖의 시프트도 화면에서 누락되지 않도록 합니다. 영업시간·시프트 정보가 모두 없는 경우 9:00~21:00을 기본값으로 사용합니다.

→ 구현 상세는 [구현 상세서: 시프트표](../implementation/shift-table.ko.md)를 참조하세요.
