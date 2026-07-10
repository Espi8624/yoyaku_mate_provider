# 개발 과정에서 배운 것들 (Lessons Learned)

> 작성일: 2026-07-10

---

## 멱등성(Idempotency) 로직의 필요성 체감

모바일 환경(가게 와이파이, LTE 망 전환 등)의 불안정성으로 인해 '대기 등록' 요청이 서버에 도달했음에도 클라이언트가 타임아웃을 겪는 상황이 발생했습니다. 
서버에서 Auto Increment로 ID를 맡기면 재시도 시 중복 등록되는 치명적인 문제가 발생합니다.
클라이언트에서 고유 식별자(`waiting_id`)와 등록 시간(`registration_time`)을 직접 생성하여 보내도록 설계(멱등성 보장)함으로써 문제를 완전히 해결했습니다.

→ [클라이언트 멱등성 구현](../implementation/idempotency.ko.md)

---

## 대용량 JSON 파싱 시 Isolate 분리를 통한 버벅임(Jank) 해결

통계 대시보드에서 긴 기간의 데이터를 불러올 때, UI 스레드에서 수천 개의 JSON 노드를 파싱하다 보니 프로그레스 스피너가 멈추거나 애니메이션이 끊기는 현상이 발생했습니다.
Flutter의 `compute()` 함수를 도입하여 JSON 파싱을 별도의 백그라운드 스레드(Isolate)로 분리한 후, 부드러운 60fps 화면 전환을 유지할 수 있었습니다.

```dart
// Main UI Isolate에서 파싱 (버벅임 발생)
final data = jsonDecode(response.body);

// Background Isolate에서 파싱 (해결)
final data = await compute(jsonDecode, response.body);
```

---

## 하드웨어 연동 시 OS 호환성(Camera, Printer) 대응

1. **카메라(QR)**: `mobile_scanner` 라이브러리를 사용해 직원들이 복잡한 매장 ID를 직접 입력하는 대신 QR 스캔 한 번으로 연동되도록 하여 사용성을 극대화했습니다. 
2. **프린터**: 저수준 Bluetooth 프로토콜(ESC/POS)로 직접 통신하려 했으나 기기 호환성 지옥에 빠질 뻔했습니다. 이를 포기하고 `pdf` 라이브러리로 영수증 템플릿을 그린 후, OS 기본 인쇄 시스템(`printing` 라이브러리)으로 넘기는 방식을 택하여 **거의 모든 브랜드의 네트워크/블루투스 프린터 호환성**을 확보했습니다.

---

## 실시간 SSE 소켓과 Provider의 결합

웹소켓 대비 가벼운 SSE(Server-Sent Events)를 Flutter `http`의 Stream으로 처리했습니다.
스트림으로 수신한 데이터를 `Provider`(ViewModel)에 전달할 때, 지수 백오프(Exponential Backoff) 재연결 로직을 서비스 레이어 깊숙이 캡슐화하여 UI는 연결 끊김을 신경 쓰지 않고 단순히 `waitingList` 상태만 바라보도록 설계한 것이 유지보수에 큰 도움이 되었습니다.
