# SSE 구독 클라이언트 구현

> 최종 수정: 2026-07-10  
> 관련 파일: [`lib/services/waiting_service.dart`](../../lib/services/waiting_service.dart)

## 개요

매장 직원이 보고 있는 대기 현황 화면이 서버와 실시간으로 동기화되도록, 서버가 푸시하는 Server-Sent Events(SSE)를 수신합니다.

---

## 구현 방식

Flutter 내장 `http` 패키지의 `Stream` 처리 기능을 사용하여 SSE 스트림을 구현했습니다.

```dart
final request = http.Request(
  'GET',
  Uri.parse('$_baseUrl/api/waiting-list/stream?store_id=$storeId'),
);
request.headers['Accept'] = 'text/event-stream';

_client!.send(request).then((response) {
  response.stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        if (line.startsWith('data: ')) {
          // JSON 파싱 및 데이터 반영
        }
      });
});
```

---

## 지수 백오프 (Exponential Backoff) 재연결

모바일 기기는 이동 중이거나 매장 내 구석에서 와이파이 연결이 자주 끊길 수 있습니다. 연결이 끊어지면 **서버에 과부하를 주지 않으면서 자동으로 재연결**을 시도합니다.

- 연결 실패 시 즉시 재연결하지 않고, `3초 -> 6초 -> 12초 -> ...` 순으로 대기 시간을 2배씩 늘려 재연결을 시도합니다.
- 최대 대기 시간은 `60초`로 제한(`clamp`)합니다.

```dart
void _handleDisconnect(String storeId) {
  // 지수 백오프: 3s -> 6s -> 12s -> ... 최대 60초
  final delaySeconds = (3 * (1 << _reconnectAttempts)).clamp(3, 60);
  _reconnectAttempts++;

  _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
    connectToStream(storeId);
  });
}
```

- 성공적으로 연결되면 `_reconnectAttempts = 0`으로 초기화됩니다.
