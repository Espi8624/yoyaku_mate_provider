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

---

## Implementation (구현 상세)

| 문서 | 설명 |
|------|------|
| [architecture.md](./implementation/architecture.ko.md) | 프로젝트 구조 및 데이터 흐름 |
| [sse-client.md](./implementation/sse-client.ko.md) | SSE 구독 클라이언트 (지수 백오프 재연결) |
| [idempotency.md](./implementation/idempotency.ko.md) | 클라이언트 멱등성 키 생성 및 전달 |

---

## Decisions (기술 결정)

| 문서 | 결정 내용 |
|------|----------|
| [ADR-001-provider-state.md](./decisions/ADR-001-provider-state.ko.md) | Provider 패턴 상태 관리 선택 이유 |

---

## Troubles (트러블슈팅 / 회고)

| 문서 | 설명 |
|------|------|
| [001-lessons-learned.md](./troubles/001-lessons-learned.ko.md) | SSE 재연결, 멱등성, 로컬 캐시, fl_chart 성능 개선 |

---

## Refactoring (리팩토링)

*기록 예정*
