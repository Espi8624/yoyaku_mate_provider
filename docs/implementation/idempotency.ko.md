# 클라이언트 멱등성 보장 로직 (Idempotency)

> 최종 수정: 2026-09-18
> 관련 파일: [`lib/pages/waiting_page/waiting_providers.dart`](../../lib/pages/waiting_page/waiting_providers.dart)

## 문제 상황

모바일 기기의 네트워크 환경이 불안정할 때, 직원이 "대기 등록" 버튼을 눌렀으나 서버의 응답(Timeout)을 받지 못해 다시 버튼을 누르는 경우가 발생할 수 있습니다.
서버는 정상 처리했으나 클라이언트만 모르는 경우, **동일한 손님이 대기열에 두 번 등록**되는 심각한 문제가 발생합니다.

---

## 2026-09-18 이전에는 동작하지 않았다

이 문서는 원래 "재전송 시 이전에 생성했던 동일한 `clientWaitingId`를 함께 전송한다"고
적고 있었지만, **실제 코드는 그렇게 되어 있지 않았다.** `addWaitingItem`이 호출될 때마다
새 키를 만들고 있었다.

```dart
// 수정 전: 버튼을 누를 때마다 새 키
final randomSuffix = (100 + (now.microsecondsSinceEpoch % 900)).toString();
final clientWaitingId = "$dateStr-$timeStr-$msStr-$randomSuffix";
```

즉 서버에서 보면 재전송이 아니라 **별개의 등록**이었고, 막으려던 이중 등록이 그대로 발생했다.
서버 쪽에도 유니크 인덱스가 없었기 때문에(문서에는 "Unique Index 검사"라고 적혀 있었지만
실제로는 non-unique였다), 양쪽 모두 설계 문서만 있고 구현이 따라오지 않은 상태였다.

> **교훈:** "이렇게 동작한다"고 적힌 문서는 그렇게 동작한다는 증거가 아니다.
> 이 문서는 관련 파일로 `waiting_screen_viewmodel.dart`를 가리키고 있었는데,
> 그 파일은 Riverpod 마이그레이션 때 없어진 지 오래였다. 문서가 낡았다는 신호는
> 그때 이미 있었다.

---

## 현재 구현

### 1. 키는 "등록 1건"마다 발행한다

키를 보관했다가 **같은 내용의 재시도에서 재사용**한다. 성공하면 버린다.

```dart
// waiting_providers.dart
String? _pendingWaitingId;
String? _pendingWaitingFingerprint;
```

- 송신 직전에 기록한다 → 예외로 빠져나가면 남는다 → 다음 시도에서 재사용된다
- 성공하면 즉시 `null`로 되돌린다 → 다음 등록은 새 키로 시작한다

### 2. 지문(fingerprint)을 함께 들고 다닌다

**이게 핵심이다.** 키만 보관하면, 손님 A 등록에 실패한 뒤 손님 B를 등록할 때
A의 키가 쓰인다. 만약 A의 등록이 실은 서버에서 성공해 있었다면, B를 등록한 줄 알았는데
**A의 레코드가 돌아온다.** 매장에서는 손님을 연달아 등록하는 게 정상이므로 실제로 일어난다.

```dart
String waitingFingerprint(Map<String, dynamic> data)   // 인원·연락처·비고·메뉴로 구성
String resolveWaitingId({pendingId, pendingFingerprint, fingerprint, freshId})
```

`resolveWaitingId`는 **지문이 일치할 때만** 이전 키를 재사용한다.

| 상황 | 결과 |
|---|---|
| 같은 내용의 재시도 | 이전 키 재사용 → 서버가 기존 레코드 반환 (이중 등록 방지) |
| 다른 손님 등록 | 새 키 → 정상적으로 새 레코드 생성 |
| 보류 키 없음 / 지문 소실 | 새 키 (안전 측으로 판단) |

두 함수 모두 순수 함수로 분리해 `test/waiting_idempotency_test.dart`에서 검증한다.
판단을 틀리면 **항상 새 키 = 이중 등록**, **항상 재사용 = 남의 번호표** 중 하나가 되고,
둘 다 손님에게 직접 보이는 불량이다.

### 3. `registration_time`은 매번 갱신한다

키와 달리 시각은 재시도마다 새로 만든다. 키와 함께 고정하면 한참 뒤에 재시도했을 때
옛 시각으로 등록되어 대기 순서가 어긋난다.

---

## 서버 측과의 관계

클라이언트만으로는 완결되지 않는다. 동시에 도착한 두 재전송은 클라이언트가 같은 키를
보내더라도, 서버가 "조회 후 삽입"을 하면 둘 다 "없음"을 보고 둘 다 삽입한다.
그래서 서버 쪽에 `(store_id, waiting_id)` 유니크 인덱스가 함께 필요하다.

자세한 내용은 `yoyaku_mate_server/docs/implementation/idempotency.ko.md` 참조.
