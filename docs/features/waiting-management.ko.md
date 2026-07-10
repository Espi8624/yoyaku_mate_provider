# 실시간 대기열 관리 (Waiting Management)

> 최종 수정: 2026-07-10  
> 관련 파일: [`lib/pages/waiting_page/waiting_screen.dart`](../../lib/pages/waiting_page/waiting_screen.dart), [`lib/pages/waiting_page/waiting_screen_viewmodel.dart`](../../lib/pages/waiting_page/waiting_screen_viewmodel.dart)

## 개요

매장 직원이 현재 대기 중인 손님 목록을 모니터링하고, 입장 호출 및 상태 업데이트(완료/취소)를 실시간으로 제어할 수 있는 핵심 기능입니다.

---

## 탭(필터) 구성

대기 목록은 3개의 탭으로 필터링되어 표시됩니다.
1. **전체 (All)**: 모든 상태의 손님
2. **대기 중 (Waiting)**: `waiting` (대기 중) 및 `notified` (호출됨) 상태의 손님
3. **완료 (Completed)**: `completed` (입장 완료) 상태의 손님

---

## 손님 상태 제어 흐름

직원은 목록의 각 아이템에 있는 버튼을 통해 손님의 상태를 제어합니다.

```
[등록됨 (waiting)]
       │
       ├─▶ 호출 버튼 ──▶ [호출됨 (notified)] ──▶ Push 알림 / SSE로 손님 기기에 알림
       │
       ├─▶ 완료 버튼 ──▶ [입장 완료 (completed)]
       │
       └─▶ 취소 버튼 ──▶ [취소됨 (cancelled)] ──▶ (사유 선택 모달)
```

### 낙관적 업데이트 (Optimistic Update)

호출, 완료, 취소 등 상태 변경 요청 시, 서버 응답을 기다리지 않고 로컬 UI 상태를 즉시 변경하여 조작 지연(Lag)을 없앴습니다. (`_isPerformingOptimisticUpdate` 플래그 사용)

---

## 수동 대기 등록

모바일 앱 내에서도 QR코드를 찍지 않고 직원이 직접 대기 손님을 등록할 수 있습니다.
- 인원, 연락처, 국적, 메모 입력 지원
- 오프라인 환경 고려 및 데이터 중복 생성 방지를 위해 **멱등성 키(Idempotency Key)** 를 로컬에서 생성하여 전송합니다.

→ [클라이언트 멱등성 구현](../implementation/idempotency.ko.md) 참조.

---

## 자동 갱신 (SSE)

화면을 열면 초기 데이터를 REST API로 한 번 불러오고, 즉시 SSE(Server-Sent Events) 스트림에 연결되어 다른 직원이 상태를 변경하거나 손님이 취소했을 때 화면이 자동으로 갱신됩니다.

→ [SSE 클라이언트 구현](../implementation/sse-client.ko.md) 참조.
