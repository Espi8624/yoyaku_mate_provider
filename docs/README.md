# docs — yoyaku_mate_provider ドキュメントインデックス

## 構造

```
docs/
├── features/           # 機能仕様 (何をするのか)
├── implementation/     # 技術実装詳細 (どのように実装したのか)
├── decisions/          # 技術選定根拠 (ADR)
├── troubles/           # トラブルシューティング / 振り返り記録
└── refactoring/        # リファクタリング記録
```

---

## Features (機能仕様)

| ドキュメント | 説明 |
|------|------|
| [waiting-management.md](./features/waiting-management.md) | リアルタイム待機列管理 (呼び出し、入店、キャンセル) |
| [ticket-printing.md](./features/ticket-printing.md) | 感熱プリンター待機整理券発券システム |
| [statistics-dashboard.md](./features/statistics-dashboard.md) | 待機統計分析ダッシュボード |

---

## Implementation (実装詳細)

| ドキュメント | 説明 |
|------|------|
| [architecture.md](./implementation/architecture.md) | プロジェクト構造およびデータフロー |
| [sse-client.md](./implementation/sse-client.md) | SSE購読クライアント (指数バックオフ再接続) |
| [idempotency.md](./implementation/idempotency.md) | クライアント側での冪等性キーの生成と伝送 |

---

## Decisions (技術決定)

| ドキュメント | 決定内容 |
|------|----------|
| [ADR-001-provider-state.md](./decisions/ADR-001-provider-state.md) | Provider パターンによる状態管理選定の理由 |

---

## Troubles (トラブルシューティング / 振り返り)

| ドキュメント | 説明 |
|------|------|
| [001-lessons-learned.md](./troubles/001-lessons-learned.md) | SSE再接続、冪等性、ローカルキャッシュ、fl_chart描画パフォーマンス改善の振り返り |

---

## Refactoring (リファクタリング)

*記録予定*
