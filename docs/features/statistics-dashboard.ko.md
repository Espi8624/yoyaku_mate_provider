# 대기 통계 분석 대시보드 (Statistics Dashboard)

> 최종 수정: 2026-09-06
> 관련 파일: [`lib/pages/statistics_page/statistics_screen.dart`](../../lib/pages/statistics_page/statistics_screen.dart), [`lib/services/statistics_service.dart`](../../lib/services/statistics_service.dart), [`yoyaku_mate_server/handlers/statistics_handler.go`](../../../yoyaku_mate_server/handlers/statistics_handler.go)

## 개요

매장의 대기열 데이터를 "오늘" 또는 "이번주(일~토)" 두 가지 뷰로만 시각화하여, 피크 시간대 파악과 운영 판단에 도움을 주는 대시보드입니다.

이전에는 월간·연간·임의 날짜 범위 지정과, 과거 기간으로 이동(◀▶)하는 기능도 제공했지만, 실제로는 "오늘 혼잡도 확인", "이번주 추이를 지난주와 비교" 이외의 사용 시나리오는 거의 없다고 판단해 기능을 축소했습니다. 이와 함께 항상 0%로 고정 표시되던 전주 대비 배지(`wow_growth_rate`) 버그도 해소했습니다.

---

## 데이터 조회 구조

- **인증 방식**: Firebase Auth `idToken`을 Bearer 토큰으로 헤더에 실어 API 호출.
- **기간 옵션 (`period`)**:
  - `auto` (기본값): 오늘만. 매장 타임존 기준 시간대별(0~23시)로 집계.
  - `weekly`: 이번주(일요일~토요일) 고정. 요일별(일~토)로 집계. **과거 특정 주를 지정해서 조회할 수는 없음**(항상 "직전 이번주"만).
- **비교 기준**: `auto`는 어제, `weekly`는 지난주(동일한 일~토 범위)와 자동으로 비교.
- **JSON 파싱 최적화**: 응답 파싱은 Flutter의 `compute()` 함수를 통해 별도 Isolate(백그라운드 스레드)에서 처리하여 UI 스레드 버벅임(Jank)을 방지.

---

## 그래프 시각화 (fl_chart)

`fl_chart` 라이브러리를 사용하여 모바일 환경에 최적화된 부드러운 애니메이션 바 차트를 렌더링합니다.

### 주요 지표
1. **오늘/이번주 하이라이트**: 방문자수·취소수·No-Show수를 탭으로 전환하여 표시. 방문자수 탭에서만 전일 대비/전주 대비 증감률 배지를 표시.
2. **평균 대기시간** · **No-Show율**: 선택된 기간(오늘 또는 이번주)의 집계값.
3. **시간대별 / 요일별 추이 (Bar Chart)**: 선택된 지표(방문자·취소·노쇼)를 오늘이면 시간대별, 이번주면 요일별 막대로 표시하고, 비교 대상 기간 값을 툴팁으로 함께 보여줌.

### 렌더링 성능 최적화
- `fl_chart`는 데이터 변경 시 애니메이션을 재생하며 다시 그리므로 렌더링 비용이 발생함.
- 그래프 영역을 `DynamicChartCard`로 분리하여, 지표/기간 전환 시 그래프 부분만 다시 그려지도록 격리했습니다.
