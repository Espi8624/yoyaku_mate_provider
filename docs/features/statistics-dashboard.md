# 待機統計分析ダッシュボード (Statistics Dashboard)

> 最終更新: 2026-07-10  
> 関連ファイル: [`lib/pages/statistics_page/statistics_screen.dart`](../../lib/pages/statistics_page/statistics_screen.dart), [`lib/services/statistics_service.dart`](../../lib/services/statistics_service.dart)

## 概要

店舗のこれまでの待機列データをグラフとして可視化し、混雑する時間帯の把握や運用の計画に役立てることができる分析ダッシュボードです。

---

## データ取得の構造

- **認証方式**: Firebase Auth の `idToken` を Bearer ヘッダーに付与して管理者用APIをリクエスト。
- **期間オプション (Period)**: 
  - `auto` (デフォルト: 今日)
  - 特定日 (`date`)
  - 自由設定範囲 (`start_date`, `end_date`)
- **JSONパースの最適化**: 統計用など大容量データのパース時には、Flutterの `compute()` 関数を介してバックグラウンドの別スレッド (Isolate) 上でパース処理を実行し、UIスレッドが一時的にフリーズ（Jank）する現象を完全に防ぎます。

---

## グラフビジュアライズ (fl_chart)

`fl_chart` ライブラリを採用し、スムーズで滑らかなモバイル向けアニメーション付きグラフをレンダーします。

### 表示する主な指標
1. **時間帯別の混雑度 (Bar Chart)**: どの時間帯に最も多くの待機受付が発生したか。
2. **平均待ち時間の推移 (Line Chart)**: 顧客の平均待機時間の変化傾向。
3. **入店完了/キャンセル比率 (Pie Chart)**: 受付数に対する実入店率とNo-Show率。

### 描画パフォーマンスの最適化
- `fl_chart` は描画データが更新されるたびに滑らかなアニメーションを実行するため、リビルドの負荷が大きいです。
- グラフ更新時、無関係な他のテキストUI等まで引きずられてリビルドが走らないよう、 `Selector` を活用して再描画スコープをグラフパーツ単体に限定・隔離しました。
