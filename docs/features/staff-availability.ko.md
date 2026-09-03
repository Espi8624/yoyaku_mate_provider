# 스태프 근무 가능 시간 입력·관리 (Staff Availability)

> 최종 수정: 2026-08-30  
> 관련 파일: [`lib/pages/profile_page/widgets/views/personal_profile_view.dart`](../../lib/pages/profile_page/widgets/views/personal_profile_view.dart), [`lib/pages/profile_page/dialogs/availability_dialog.dart`](../../lib/pages/profile_page/dialogs/availability_dialog.dart), [`lib/pages/profile_page/dialogs/day_availability_dialog.dart`](../../lib/pages/profile_page/dialogs/day_availability_dialog.dart), [`lib/pages/staff_management_page/widgets/staff_management_view.dart`](../../lib/pages/staff_management_page/widgets/staff_management_view.dart)

## 개요

향후 "버튼 클릭 한 번으로 시프트표 자동 생성" 기능의 기반으로, 스태프 본인이 요일별로 근무 가능한 시간대(오전·오후)를 입력하고, 매장 매니저가 스태프 관리 화면에서 이를 요일 단위로 조회·수정할 수 있는 기능입니다.

---

## 1. 본인 입력 (개인 프로필 화면)

역할(관리자/직원)에 관계없이 모든 사용자가 공통으로 보는 "일반" 프로필 탭에 "근무 정보" 섹션이 표시됩니다.

* "근무 가능 시간" 항목을 탭하면, 7개 요일을 한 번에 설정할 수 있는 `AvailabilityDialog`가 열립니다.
* 요일별로 `오전` / `오후`를 `ChoiceChip`으로 복수 선택할 수 있으며, 선택이 없는 요일은 근무 불가로 처리됩니다.
* 저장하면 `PATCH /api/stores/{storeId}/staff/me/availability`가 호출됩니다.

---

## 2. 매니저의 조회·수정 (스태프 관리 화면)

스태프 관리 화면의 각 스태프 카드에는, "권한설정"과 독립적으로 여닫을 수 있는 "근무 가능일" 섹션이 있습니다.

* 탭해서 펼치면 월~일 7개 요일이 원형 뱃지(56×56)로 표시됩니다.
* **근무 가능한 요일은 강조색, 불가능한 요일은 회색**으로 시각적으로 구분됩니다.
* 뱃지 하나하나가 독립된 버튼이며, **특정 요일 뱃지를 탭하면 그 요일 하루치 시간대만 편집하는 경량 다이얼로그(`DayAvailabilityDialog`)**가 열립니다. 7개 요일을 한꺼번에 편집할 필요가 없습니다.
* 확정하면 탭한 요일 외 기존 값은 그대로 유지한 채 `PATCH /api/stores/{storeId}/staff/{staffId}/availability`가 호출됩니다.

---

## 3. UI 설계 포인트

* 요일 뱃지는 한 손 조작에서도 누르기 편하도록 44px 이상의 탭 영역을 확보하는 형태로 56×56으로 설정했습니다.
* "근무 가능일"은 "권한설정" 드롭다운 안쪽이 아니라 독립된 개폐 섹션으로 배치되어, 권한설정을 펼치지 않고도 근무 가능일만 따로 열고 닫을 수 있습니다.

→ 구현 상세는 [구현 상세서: 스태프 근무 가능 시간](../implementation/staff-availability.ko.md)을 참조.
