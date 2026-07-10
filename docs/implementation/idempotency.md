# クライアントにおける冪等性保証 (Idempotency)

> 最終更新: 2026-07-10  
> 関連ファイル: [`lib/pages/waiting_page/waiting_screen_viewmodel.dart`](../../lib/pages/waiting_page/waiting_screen_viewmodel.dart)

## 課題の背景

店舗のネットワーク（Wi-Fi、LTEの境界など）は電波状況が不安定になることが頻繁にあります。  
スタッフがお客様を代理で大機列へ追加する際、通信が不安定なためにサーバーからの正常な応答（APIレスポンス）を受け取れず、タイムアウトが発生することがあります。

この時、画面上にはエラーが表示されるためスタッフは「登録」ボタンを再クリックしますが、実際には最初のクリックですでにサーバー側の処理は成功していた場合、 **同一の顧客データが二重に登録され、順番号がずれてしまう** という深刻な問題が発生します。

---

## 解決策: クライアント主導の一意なID生成

サーバー側でシーケンシャルなIDを自動発行するのではなく、リクエストを送信するより前に **クライアント（アプリ）側で一意な冪等性キー (`waiting_id`) を生成** してBodyに含めます。

### 冪等性キー生成規則 (Dart)

```dart
final jstNow = DateTime.now().toUtc().add(const Duration(hours: 9));

// YYYYMMDD-HHmmss-SSS フォーマット
final dateStr = "${jstNow.year}${jstNow.month}${jstNow.day}";
final timeStr = "${jstNow.hour}${jstNow.minute}${jstNow.second}";
final msStr = jstNow.millisecond;

// マイクロ秒に基づく一意のランダムな末尾3桁 (100〜999)
final randomSuffix = (100 + (jstNow.microsecondsSinceEpoch % 900)).toString();

final clientWaitingId = "$dateStr-$timeStr-$msStr-$randomSuffix";
```

### 二重登録防止の仕組み

1. アプリは生成した `clientWaitingId` を付与してAPIを叩く。
2. ネットワーク遮断により、サーバーの処理は完了したがアプリ側で応答を取得できずにタイムアウト。
3. スタッフが「再試行」ボタンをクリック。
4. アプリは、同じ受付データに対して **さきほど生成した `clientWaitingId` と全く同じID** を再送信。
5. サーバーは受信した `waiting_id` がデータベースに既に存在するか確認。
6. すでに保存されているため、新規レコードの追加は行わず、既存の登録成功データをそのまま返却（冪等性の維持）。

これにより、通信環境が劣悪な店舗の現場であっても、正確に一度だけ待機登録が行われるようになります。
