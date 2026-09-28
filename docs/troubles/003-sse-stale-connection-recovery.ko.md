# 003: SSE가 끊긴 뒤 복귀하지 않아 대기 리스트가 실시간 갱신되지 않는 문제

> 작성일: 2026-09-18
> 상태: 해결됨 (Resolved)
> 관련 파일: [`lib/services/waiting_service.dart`](../../lib/services/waiting_service.dart), [`lib/pages/waiting_page/waiting_providers.dart`](../../lib/pages/waiting_page/waiting_providers.dart)

---

## 현상 (Symptom)

Android 에뮬레이터 테스트 중, 대기 리스트 화면에서 **대기를 추가해도 화면에 바로 반영되지 않았다.**
대기 리스트는 SSE로 실시간 갱신되는 설계인데도, 화면을 나갔다 들어오거나
당겨서 새로고침하기 전까지는 새 대기가 나타나지 않는 상태였다.

---

## 조사 (Investigation)

먼저 서버를 의심했으나, 개발 서버에 직접 SSE로 접속해 보니 **전송은 정상**이었다.

```
21:55:24 data: []        ← 접속 직후 초기 데이터
21:55:48 data: :ping     ← 30초 주기 heartbeat
```

같은 것을 Dart `package:http`로 재현해도 정상 수신되었으므로,
**전송 계층이 아니라 앱 측 연결 관리에 원인이 있다**고 판단하고 `waiting_service.dart`를 정밀 검토했다.

참고로 `waiting_service.dart`는 `print`가 전부 주석 처리되어 있어
SSE의 실패 경로가 하나도 남김없이 삼켜지고 있었고, 이 때문에 원인 분리에 시간이 걸렸다.

---

## 원인 분석 (Root Cause)

### 1. 끊김을 감지하지 못해 두 번 다시 재연결되지 않음 (주원인)

```dart
// 수정 전
void connectToStream(String storeId) {
  if (_isConnected && _lastStoreId == storeId) return;
```

`_isConnected`는 `onDone` / `onError`가 발생했을 때만 `false`가 된다.
그런데 모바일 회선 전환이나 백그라운드 복귀에서는 소켓이
**half-open(한쪽만 닫힌 상태)**으로 조용히 죽는 경우가 있고, 이때는 두 콜백 모두 발생하지 않는다.

결과적으로 `_isConnected`가 `true`로 남아, 위 early return 때문에
**화면을 나갔다 들어와도 앱을 포그라운드로 복귀시켜도 두 번 다시 재연결되지 않는다.**
`stopPolling()`은 외부에서 한 번도 호출되지 않으므로, 이 상태에서 빠져나올 경로가 아예 없었다.

서버는 30초마다 heartbeat를 보내 이 상황을 막으려 했지만,
클라이언트는 `json.decode(":ping")`의 예외를 빈 `catch`로 버릴 뿐
**생존 확인에 전혀 사용하지 않고 있었다.**

### 2. 재연결이 느림

```dart
// 수정 전
final delaySeconds = (3 * (1 << _reconnectAttempts)).clamp(3, 60);
```

지수 백오프 상한이 60초인 데다, `_reconnectAttempts` 리셋이
**HTTP 200 응답을 받은 시점**에만 일어났다. 서버가 콜드 스타트 중이라 몇 번 실패하면
재연결 간격이 최대 1분까지 벌어진다.

### 3. SSE에 세션 헤더가 붙지 않음

SSE만 공유 `apiClient`가 아니라 생 `http.Client()`를 사용하고 있어
`X-Session-Id`가 부착되지 않았다. 서버는 이를 비스태프 접속으로 보고
`contact`(전화번호)를 가린 데이터를 전송한다.

그래서 **초기 표시(REST, 세션 헤더 있음)에서는 보이던 전화번호가
SSE 갱신이 한 번 들어오면 사라지는** 별도의 버그를 유발하고 있었다.

### 4. 구독이 초기 취득 3왕복 뒤였음

`waiting_providers.dart`의 `build()`는 대기 리스트 취득·`board_key` 취득·QR 토큰 취득의
**3왕복이 끝난 뒤에야** 구독을 시작했다. 이 사이(수백 밀리초)에 발생한 갱신은
broadcast 스트림에 구독자가 없어 버려지고, 다음 갱신까지 반영되지 않는다.

### 5. dispose된 Notifier에 대한 구독 리크

```dart
ref.onDispose(() => _subscription?.cancel());
...
await Future.wait([...]);   // ← 이 사이에 invalidate되면
_subscribeToStream(storeId); // ← onDispose 이후에 구독이 걸린다
```

대기 화면은 하단 내비게이션의 `pages[_selectedIndex]`로 전환되므로 탭 이동마다
Notifier가 dispose된다. 게다가 라이프사이클 감시용 `useEffect`가 첫 프레임에
`ref.invalidate`를 호출하기 때문에, **`build()`의 await 중에 dispose되는 케이스가 상시화**되어 있었다.

이때 `onDispose`가 먼저 실행되고 그 뒤에 구독이 걸리므로,
**두 번 다시 `cancel`되지 않는 리스너가 화면 진입마다 하나씩 쌓이고** 있었다.

---

## 해결책 (Solution)

### 1. watchdog에 의한 끊김 감지

```dart
// 서버의 heartbeat는 30초 주기. 2회분을 놓쳐도 오탐하지 않을 여유를 둔다
static const Duration _staleThreshold = Duration(seconds: 45);
static const Duration _watchdogInterval = Duration(seconds: 15);
```

15초 주기로 최종 수신 시각을 확인하고, 45초간 전혀 수신이 없으면 half-open으로 보고 다시 연결한다.

중요한 설계 포인트로, **수신한 행은 내용을 불문하고 생존 확인으로 센다.**
`data:` 행으로 한정하면 서버 측 heartbeat 형식이 바뀌는 순간 감지가 깨지기 때문이다
(실제로 서버 측에서는 이후 `data: :ping` → `:ping` 주석 형식으로 수정했다).

### 2. 접속 세대 번호 (generation)

watchdog을 넣으면 강제 재연결이 늘어나므로, **오래된 접속에서 늦게 도착한
`onDone` / `onError`가 방금 새로 만든 접속을 말려들게 해 끊어버리는** 경쟁 조건이 드러난다.

접속할 때마다 증가시키는 세대 번호를 두고, 콜백과 await 재개 지점마다
자기 세대가 최신인지 확인하도록 했다. `_handleDisconnect` 자신도 세대를 진행시키므로,
같은 접속에서 이중으로 끊김 통지가 와도 재연결은 1회만 일어난다.

### 3. 그 외

- 백오프 상한을 60초에서 10초로 단축하고, 카운터 리셋을 **최초 수신 시점**으로 변경
- `SessionService`에서 `X-Session-Id`를 가져와 수동 부착 (공유 `apiClient`는
  접속 생존 기간을 자체 관리하는 사정상 `close()`할 수 없어 경유 불가)
- 구독을 `build()`의 await보다 앞으로 이동. 완료 전에 도착한 분은 `_pendingItems`에 대피시키고,
  초기 취득 결과보다 우선 채택한다 (구독 시작 후 도착한 데이터가 더 최신이므로)
- `_disposed` 플래그로 dispose 이후의 콜백을 차단
- 실패 경로에 `kDebugMode` 조건부 로그 추가

---

## 결과와 정리 (Consequences)

- 끊겨도 watchdog이 45초 이내에 감지하고 3초 뒤 재연결하므로, 최악의 경우에도 1분 안쪽에 복귀한다
  (서버 콜드 스타트 약 6초 포함)
- 전화번호가 SSE 갱신마다 사라지는 문제도 함께 해소되었다
- **교훈 1**: "연결됨 플래그"는 연결의 생존을 의미하지 않는다. TCP는 상대가 조용히 사라져도
  이쪽에 알려주지 않는다. keep-alive는 받는 쪽이 그것을 **실제로 생존 판정에 사용해야** 비로소 의미가 생긴다
- **교훈 2**: 예외를 빈 `catch`로 삼키면 그 경로는 영원히 보이지 않게 된다.
  이번에는 heartbeat 파싱 실패를 버리고 있었기 때문에 "heartbeat는 도착하고 있다"는
  가장 중요한 단서가 로그에 전혀 나타나지 않았다
- **교훈 3**: 재연결 처리를 추가할 때는 오래된 접속의 뒷정리가 새 접속을 망가뜨리지 않는지 반드시 확인한다.
  "끊김을 감지해 다시 연결한다"만 구현하면, 늦게 도착한 끊김 통지로 제 발등을 찍는다

---

## 관련 문서

- [001: SSE 재연결, 멱등성, 로컬 캐시, fl_chart 성능 개선 회고](./001-lessons-learned.ko.md)
- [002: 무채색 시드의 ColorScheme이 청록색이 되는 문제](./002-m3-seed-color-teal.ko.md)
- 서버 측 대응: `yoyaku_mate_server`의 `docs/troubles/003-sse-heartbeat-and-zombie-cleanup.ko.md`
