# 대기 통계 분석 대시보드 (Statistics Dashboard)

> 최종 수정: 2026-07-10  
> 관련 파일: [`lib/pages/statistics_page/statistics_screen.dart`](../../lib/pages/statistics_page/statistics_screen.dart), [`lib/services/statistics_service.dart`](../../lib/services/statistics_service.dart)

## 개요

매장의 대기열 현황을 수치화하고 시각화하여, 피크 시간대 파악과 운영 효율성을 높일 수 있는 그래프 대시보드입니다.

---

## 데이터 조회 구조

- **인증 방식**: Firebase Auth `idToken`을 Bearer 토큰으로 헤더에 실어 백엔드 API 호출.
- **기간 옵션 (Period)**: 
  - `auto` (기본, 오늘)
  - 특정 날짜 (`date`)
  - 기간 (`start_date`, `end_date`)
- **JSON 파싱 최적화**: `compute()` 함수를 사용하여 응답 JSON을 별도의 Isolate(백그라운드 스레드)에서 파싱, 대량의 데이터 응답 시 UI 스레드 버벅임(Jank)을 방지합니다.

---

## 그래프 시각화 (fl_chart)

`fl_chart` 라이브러리를 사용하여 모바일 환경에 최적화된 부드럽고 터치 가능한 그래프를 렌더링합니다.

### 주요 지표
1. **시간대별 대기 건수 (Bar Chart)**: 어느 시간대에 손님이 몰렸는지 막대 그래프로 표시.
2. **평균 대기 시간 추이 (Line Chart)**: 시간 경과에 따른 대기 시간의 변화.
3. **완료/취소 비율 (Pie Chart)**: 대기 등록 대비 실제 입장 비율(No-Show 파악).

### 성능 최적화
- `fl_chart`는 데이터 변경 시 애니메이션을 재생하며 다시 그리기 때문에 렌더링 비용이 발생합니다.
- 상태가 변경될 때 전체 화면이 아닌 그래프 영역만 다시 그려지도록 Provider의 `Selector`를 사용하여 렌더링을 격리(Isolation)했습니다.
