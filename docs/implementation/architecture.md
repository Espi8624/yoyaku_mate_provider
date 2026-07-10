# アーキテクチャの概要

> 最終更新: 2026-07-10

## Tech Stack

| 項目 | 技術 |
|------|------|
| Framework | Flutter |
| State Management | Provider |
| Authentication | Firebase Auth |
| HTTP Client | `http` パッケージ |
| Data Visualization | `fl_chart` |
| Local Database | `sqflite`, `shared_preferences` |
| Hardware | `mobile_scanner` (QR), `pdf` & `printing` (領収書) |

---

## ディレクトリ構造

```
lib/
├── models/               # JSON変換用データモデルクラス (WaitingList, Store など)
├── pages/                # 画面単位のフォルダ (UIおよびViewModelを含む)
│   ├── waiting_page/     # SSEを活用したリアルタイム待機リスト画面
│   ├── statistics_page/  # 統計分析ダッシュボード画面
│   ├── menu_management_page/ # メニュー・カテゴリ動的追加/編集画面
│   ├── staff_management_page/# 複数スタッフ管理・権限制御画面
│   └── store_selection/  # 店舗選択/QR連携画面
│
├── services/             # サービス層：ビジネスロジックおよびAPI通信の集約
│   ├── waiting_service.dart    # SSE接続管理、冪等性伝送処理
│   └── statistics_service.dart # バックグラウンド Isolate パース処理
│
├── utils/                # ユーティリティ (PDF設計、時間変換など)
├── widgets/              # 再利用性の高いUIコンポーネント
├── constants/            # アプリ内カラー定数(AppColors)、エンドポイント設定
├── routes.dart           # GoRouter による画面ルーティング定義
└── main.dart             # アプリの開始点、グローバル Provider の注入
```

---

## データフロー

```
Flutter UI (Pages)
    │
    ▼ (イベント / アクション)
ViewModel (ChangeNotifier)
    │
    ▼ (メソッド呼び出し)
Service Layer (services/*.dart)
    │
    ├── (REST) ──▶ Backend API (fly.io) ──▶ MongoDB
    ├── (SSE) ◀── サーバーからのリアルタイムPush通知の購読
    └── (Local) ─▶ SQLite / SharedPreferences によるオフラインキャッシュ
```

### 設計の特徴: MVVMパターン

- **Model**: `lib/models/` に配置。APIレスポンスのスキーマに対応した純粋なデータオブジェクト。
- **View**: `lib/pages/` 配下の `*_screen.dart` (または `*_page.dart`)。ビジネスロジックを持たず、UIの描画に専念。
- **ViewModel**: `*_viewmodel.dart`。Viewにバインドされる画面専用の状態（`isLoading`, `error`, 各種リストデータ）を保持し、状態更新時に `notifyListeners()` を呼び出してViewを更新。 `Provider` を介してライフサイクルが管理されます。
