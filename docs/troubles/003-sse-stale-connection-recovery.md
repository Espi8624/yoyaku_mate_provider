# 003: SSEが切断後に復帰せず、待機リストがリアルタイム更新されなくなる

> 作成日: 2026-09-18
> 状態: 解決済み (Resolved)
> 関連ファイル: [`lib/services/waiting_service.dart`](../../lib/services/waiting_service.dart), [`lib/pages/waiting_page/waiting_providers.dart`](../../lib/pages/waiting_page/waiting_providers.dart)

---

## 現象 (Symptom)

Androidエミュレータでのテスト中、待機リスト画面で**待機を追加しても画面にすぐ反映されない**。
待機リストはSSEでリアルタイム更新される設計にもかかわらず、画面を出入りするか
プルリフレッシュするまで新しい待機が現れない状態だった。

---

## 調査 (Investigation)

まずサーバー側を疑ったが、開発サーバーへ直接SSE接続したところ**配信は正常**だった。

```
21:55:24 data: []        ← 接続直後の初期データ
21:55:48 data: :ping     ← 30秒ごとのheartbeat
```

同じことをDartの `package:http` で再現しても正常に受信できたため、
**転送層ではなくアプリ側の接続管理に原因がある**と判断して `waiting_service.dart` を精査した。

なお `waiting_service.dart` は `print` がすべてコメントアウトされており、
SSEの失敗経路がひとつ残らず握り潰されていたため、この切り分けに時間がかかった。

---

## 原因分析 (Root Cause)

### 1. 切断を検知できず、二度と再接続されない (主因)

```dart
// 修正前
void connectToStream(String storeId) {
  if (_isConnected && _lastStoreId == storeId) return;
```

`_isConnected` は `onDone` / `onError` が発火したときにしか `false` にならない。
ところがモバイル回線の切り替えやバックグラウンド復帰では、ソケットが
**half-open (片側だけ閉じた状態)** のまま無言で死ぬことがあり、この場合どちらのコールバックも発火しない。

結果として `_isConnected` が `true` のまま残り、上記の早期リターンによって
**画面を出入りしてもアプリをフォアグラウンドに戻しても、二度と再接続されない**。
`stopPolling()` は外部から一度も呼ばれていないため、この状態から抜ける経路が存在しなかった。

サーバーは30秒ごとにheartbeatを送ってこの状況を防ごうとしていたが、
クライアントは `json.decode(":ping")` の例外を空の `catch` で捨てるだけで、
**生存確認にまったく使っていなかった**。

### 2. 再接続が遅い

```dart
// 修正前
final delaySeconds = (3 * (1 << _reconnectAttempts)).clamp(3, 60);
```

指数バックオフの上限が60秒で、かつ `_reconnectAttempts` のリセットが
**HTTP 200応答を受け取った時点**のみだった。サーバーがコールドスタート中などで
数回失敗すると、再接続間隔が最大1分まで開いてしまう。

### 3. SSEにセッションヘッダが付いていない

SSEだけが共有の `apiClient` ではなく生の `http.Client()` を使っていたため、
`X-Session-Id` が付与されていなかった。サーバーはこれを非スタッフ接続とみなし、
`contact` (電話番号) を伏せたデータを配信する。

そのため**初期表示 (REST、セッションヘッダあり) では見えていた電話番号が、
SSE更新が一度入ると消える**という別のバグを引き起こしていた。

### 4. 購読が初期取得3往復の後だった

`waiting_providers.dart` の `build()` は、待機リスト取得・`board_key` 取得・QRトークン取得の
**3往復が終わってから**購読を開始していた。この間 (数百ミリ秒) に発生した更新は
ブロードキャストストリームに購読者が居ないため捨てられ、次の更新まで反映されない。

### 5. dispose済みNotifierへの購読リーク

```dart
ref.onDispose(() => _subscription?.cancel());
...
await Future.wait([...]);   // ← この間にinvalidateされると
_subscribeToStream(storeId); // ← onDisposeの後に購読が張られる
```

待機画面はボトムナビの `pages[_selectedIndex]` で切り替わるため、タブ移動のたびに
Notifierがdisposeされる。加えてライフサイクル監視の `useEffect` が初回フレームで
`ref.invalidate` を呼ぶため、**`build()` のawait中にdisposeされるケースが常態化**していた。

このとき `onDispose` が先に走り、そのあとで購読が張られるため、
**二度と `cancel` されないリスナーが画面進入のたびに1つずつ蓄積**していた。

---

## 解決策 (Solution)

### 1. watchdogによる切断検知

```dart
// サーバーのheartbeatは30秒周期。2回分取りこぼしても誤検知しない余裕をとる
static const Duration _staleThreshold = Duration(seconds: 45);
static const Duration _watchdogInterval = Duration(seconds: 15);
```

15秒周期で最終受信時刻を確認し、45秒間まったく受信が無ければhalf-openとみなして張り直す。

重要な設計点として、**受信した行は内容を問わず生存確認として数える**。
`data:` 行に限定すると、サーバー側のheartbeat形式が変わった瞬間に検知が壊れるためである
(実際サーバー側では後から `data: :ping` → `:ping` のコメント形式へ修正している)。

### 2. 接続の世代番号 (generation)

watchdogを入れると強制的な張り直しが増えるため、**古い接続から遅れて届く
`onDone` / `onError` が、張り直した直後の新しい接続を巻き添えで落とす**競合が顕在化する。

接続のたびに加算する世代番号を持たせ、コールバックとawait再開の各所で
自分の世代が最新かを確認するようにした。`_handleDisconnect` 自身も世代を進めるため、
同じ接続から二重に切断通知が来ても再接続は1回だけになる。

### 3. その他

- バックオフ上限を60秒から10秒へ短縮し、カウンターのリセットを**最初の受信時**に変更
- `SessionService` から `X-Session-Id` を取得して手動で付与 (共有 `apiClient` は
  接続の生存期間を自前で管理する都合上 `close()` できないため経由できない)
- 購読を `build()` のawaitより前へ移動。完了前に届いた分は `_pendingItems` に退避し、
  初期取得の結果より優先して採用する (購読開始後に届いたデータのほうが新しいため)
- `_disposed` フラグでdispose後のコールバックを遮断
- 失敗経路に `kDebugMode` 付きのログを追加

---

## 結果と整理 (Consequences)

- 切断してもwatchdogが45秒以内に検知し、3秒後に再接続するため、最悪でも1分弱で復帰する
  (サーバーのコールドスタート約6秒を含む)
- 電話番号がSSE更新のたびに消える問題も同時に解消した
- **教訓1**: 「接続済みフラグ」は接続の生存を意味しない。TCPは相手が黙って消えても
  こちらに通知しない。keep-aliveを受け取る側が、それを**実際に生存判定に使って**初めて意味を持つ
- **教訓2**: 例外を空の `catch` で握り潰すと、その経路は永久に不可視になる。
  今回はheartbeatのパース失敗を捨てていたため、「heartbeatは届いている」という
  最重要の手がかりがログに一切現れなかった
- **教訓3**: 再接続処理を追加するときは、古い接続の後始末が新しい接続を壊さないかを必ず確認する。
  「切断を検知して張り直す」だけを実装すると、遅れて届く切断通知で自分の足を撃つ

---

## 関連ドキュメント

- [001: SSE再接続、冪等性、ローカルキャッシュ、fl_chart描画パフォーマンス改善の振り返り](./001-lessons-learned.md)
- [002: 無彩色シードのColorSchemeが青緑になる問題](./002-m3-seed-color-teal.md)
- サーバー側の対応: `yoyaku_mate_server` の `docs/troubles/003-sse-heartbeat-and-zombie-cleanup.md`
