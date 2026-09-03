# docs — yoyaku_mate_provider (Flutter App) 문서 인덱스

## 구조

```
docs/
├── features/           # 기능 사양 (무엇을 하는가)
├── implementation/     # 기술 구현 상세 (어떻게 구현했는가)
├── decisions/          # 기술 선택 근거 (ADR)
├── troubles/           # 트러블슈팅 / 회고 기록
└── refactoring/        # 리팩토링 기록
```

---

## Features (기능 사양)

| 문서 | 설명 |
|------|------|
| [waiting-management.md](./features/waiting-management.ko.md) | 실시간 대기열 관리 (호출, 완료, 취소) |
| [ticket-printing.md](./features/ticket-printing.ko.md) | 감열 프린터 티켓 출력 시스템 |
| [statistics-dashboard.md](./features/statistics-dashboard.ko.md) | 대기 통계 분석 대시보드 |
| [staff-availability.md](./features/staff-availability.ko.md) | 스태프 요일별 근무 가능 시간대 입력·조회·수정 |
| [shift-table.md](./features/shift-table.ko.md) | 스태프 관리 화면 2페이지, 주간 시프트표(Outlook/Teams풍 그리드) 생성·열람·편집 |

---

## Implementation (구현 상세)

| 문서 | 설명 |
|------|------|
| [architecture.md](./implementation/architecture.ko.md) | 프로젝트 구조 및 데이터 흐름 |
| [sse-client.md](./implementation/sse-client.ko.md) | SSE 구독 클라이언트 (지수 백오프 재연결) |
| [idempotency.md](./implementation/idempotency.ko.md) | 클라이언트 멱등성 키 생성 및 전달 |
| [staff-availability.md](./implementation/staff-availability.ko.md) | Availability 다이얼로그 2단 구성, 요일 단위 부분 업데이트 병합 로직 구현 상세 |
| [shift-table.md](./implementation/shift-table.ko.md) | PageView 스와이프 구성, 시프트 그리드 스크롤 동기화, Riverpod 프로바이더 구현 상세 |

---

## Decisions (기술 결정)

| 문서 | 결정 내용 |
|------|----------|
| [ADR-001-provider-state.md](./decisions/ADR-001-provider-state.ko.md) | Provider 패턴 상태 관리 선택 이유 (상위 대체됨, 아래 리팩토링 참고) |

---

## Troubles (트러블슈팅 / 회고)

| 문서 | 설명 |
|------|------|
| [001-lessons-learned.md](./troubles/001-lessons-learned.ko.md) | SSE 재연결, 멱등성, 로컬 캐시, fl_chart 성능 개선 |

---

## Refactoring (리팩토링)

| 문서 | 설명 |
|------|------|
| [001-provider-to-riverpod-migration.md](./refactoring/001-provider-to-riverpod-migration.ko.md) | 상태관리 아키텍처 Provider(MVVM) → Riverpod + Hooks 전면 마이그레이션 |
