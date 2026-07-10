# 클라이언트 멱등성 보장 로직 (Idempotency)

> 최종 수정: 2026-07-10  
> 관련 파일: [`lib/pages/waiting_page/waiting_screen_viewmodel.dart`](../../lib/pages/waiting_page/waiting_screen_viewmodel.dart)

## 문제 상황

모바일 기기의 네트워크 환경이 불안정할 때, 직원이 "대기 등록" 버튼을 눌렀으나 서버의 응답(Timeout)을 받지 못해 다시 버튼을 누르는 경우가 발생할 수 있습니다.
서버는 정상 처리했으나 클라이언트만 모르는 경우, **동일한 손님이 대기열에 두 번 등록(중복 결제와 유사)** 되는 심각한 문제가 발생합니다.

---

## 해결 방법: 클라이언트 주도 ID 생성

서버가 대기 ID를 생성(Auto Increment)하게 두지 않고, 클라이언트가 데이터를 전송할 때 고유한 멱등성 키(`waiting_id`)를 미리 생성하여 보냅니다.

### 멱등성 키 생성 규칙

```dart
final jstNow = DateTime.now().toUtc().add(const Duration(hours: 9));

// YYYYMMDD-HHmmss-SSS 형식
final dateStr = "${jstNow.year}${jstNow.month}${jstNow.day}";
final timeStr = "${jstNow.hour}${jstNow.minute}${jstNow.second}";
final msStr = jstNow.millisecond;

// 마이크로초 기반 3자리 난수 (100~999)
final randomSuffix = (100 + (now.microsecondsSinceEpoch % 900)).toString();

final clientWaitingId = "$dateStr-$timeStr-$msStr-$randomSuffix";
```

### 동작 원리

1. 앱에서 `clientWaitingId` 생성 후 서버로 POST 전송.
2. 타임아웃 등 에러 발생. 직원이 재전송 버튼 클릭.
3. 앱은 동일한 손님 정보라면 **이전에 생성했던 동일한 `clientWaitingId`** 를 함께 전송.
4. 서버는 MongoDB에 `waiting_id`로 `Upsert` 쿼리 또는 Unique Index 검사를 수행.
5. 데이터베이스 구조상 이미 존재하는 `waiting_id`면 중복 생성되지 않고 기존 데이터(혹은 성공 응답)를 반환.

이 설계를 통해 통신 장애가 잦은 모바일 환경에서도 안전하게 대기열 데이터를 다룰 수 있습니다.
