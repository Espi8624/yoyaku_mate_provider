# SSE 購読クライアント実装

> 最終更新: 2026-07-10  
> 関連ファイル: [`lib/services/waiting_service.dart`](../../lib/services/waiting_service.dart)

## 概要

店舗スタッフ側のアプリにおいて、大機列リストが常にバックエンドの状態と自動で同期するよう、サーバーからイベントストリーム（Server-Sent Events）をバックグラウンドで購読します。

---

## 実装のアプローチ

Flutter の標準 `http` パッケージの `Client.send()` と `Stream` 変換機能（`transform`）を利用し、追加のライブラリ（Socket.io等）なしで軽量なストリーム接続を実現しています。

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
          // JSONパースしてViewModelへストリーム通知
        }
      });
});
```

---

## 指数バックオフ (Exponential Backoff) 再接続

モバイル端末は店舗内の電波の届きにくい場所への移動などによって、接続が一時的に遮断されることが日常的に起こります。  
接続が切断された場合、 **サーバーへ集中的な負荷を与えないよう考慮しながら自動再接続** を行います。

- 切断時、直ちに再接続するのではなく、 `3秒 → 6秒 → 12秒 → ...` のように待機時間を2倍ずつ増加させて再試行の間隔を開けます。
- 最大待機時間は `60秒` に制限 (`clamp`) します。

```dart
void _handleDisconnect(String storeId) {
  // 指数バックオフ: 3s -> 6s -> 12s -> ... 最大60秒
  final delaySeconds = (3 * (1 << _reconnectAttempts)).clamp(3, 60);
  _reconnectAttempts++;

  _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
    connectToStream(storeId);
  });
}
```

- 接続が成功すると、リトライカウント `_reconnectAttempts` は直ちに `0` へリセットされます。
