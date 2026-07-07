# 📱 Yoyaku Mate - パートナー店舗向けアプリケーション（Flutter App）

> **Yoyaku Mate** パートナー向けアプリは、店舗を運営する店主およびスタッフのための **順番待ち管理・店舗設定モバイル / デスクトップアプリケーション**です。リアルタイムでのお客様待ち状況の管理、メニュー設定、スタッフ管理、来客・待ち時間統計の可視化、チケット印刷など、バックオフィスの中核機能を提供します。

---

## 🛠 Tech Stack（技術スタック）

- **Cross-Platform Framework:** Flutter（Dart）
- **State Management:** Provider（データ状態のグローバル管理）
- **Authentication:** Firebase Auth（ログイン・会員登録・パスワードリセット・メール認証）
- **Database (Local):** SQLite（`sqflite`）、`shared_preferences`（ローカルデータキャッシュおよび設定保存）
- **Routing:** Go Router（宣言的ナビゲーションルーティング）
- **AI Engine:** Google Generative AI（Gemini SDK を活用した多言語翻訳および自動化アシスタント）
- **Libraries:**
  - `fl_chart`（待ち統計チャートの可視化）
  - `mobile_scanner`（お客様 QR コードチケットのスキャンおよび検証）
  - `pdf` & `printing`（待ち番号票の PDF 生成およびレシートプリンター対応印刷）
  - `flutter_slidable`（リストスライド操作）
  - `flutter_dotenv`（環境変数ファイルのロード）

---

## ✨ Key Features（主要機能）

- **リアルタイム順番待ち制御（Queue Management）：** 待ち中のお客様の呼び出し・待ち完了処理・予約キャンセルをワンタップでリアルタイム制御します。
- **QR チケットリーダー（QR Code Scanner）：** 来店されたお客様が提示するモバイル QR チケットをカメラで即時スキャンし、待ち状態を検証します。
- **メニュー & カテゴリ管理：** 提供メニューの追加・削除・価格設定およびカテゴリ分類を管理します。
- **スタッフ管理（Staff Management）：** 勤務スタッフを追加し、アカウントごとに権限を管理します。
- **統計分析ダッシュボード：** 日別・週別の待ち人数統計および混雑時間帯レポートをチャートで可視化して確認できます。
- **印刷システム（Ticket Printing）：** レシート / サーマルプリンターと連携し、現場の待ちお客様向けに感熱印刷の番号票を発行できます。

---

## 📂 Project Structure（フォルダ構成）

```bash
lib/
├── constants/            # API キー定義および定数
├── models/               # 順番待ち・店舗・メニュー等のデータモデルクラス
├── pages/                # 主要ビジネス画面
│   ├── waiting_page/     # リアルタイム待ち状況ボードおよびお客様呼び出し画面
│   ├── menu_management/  # メニューリストおよび詳細追加・編集画面
│   ├── staff_management/ # スタッフ追加および役割変更画面
│   ├── statistics_page/  # fl_chart ベースのダッシュボード統計画面
│   ├── profile_page/     # 店舗詳細情報およびアプリ設定画面
│   └── sign_up/          # 段階別会員登録画面
├── services/             # Firebase およびバックエンドサーバー連携のビジネス API レイヤー
├── utils/                # PDF 変換・時刻パース等のユーティリティクラス
├── widgets/              # 可読性向上のために細分化した共通 UI ウィジェット
├── routes.dart           # GoRouter ベースのアプリ全体ナビゲーション定義
└── main.dart             # Flutter アプリのエントリーポイントおよびグローバルプロバイダー設定
```

---

## 🚀 Getting Started（セットアップガイド）

> [!IMPORTANT]
> 本プロジェクトはセキュリティ上の理由から、Firebase および一部の設定ファイルが `.gitignore` に登録されています。初回クローン後は以下の設定ファイルの作成が必要です。

### 1. 設定ファイルの準備

1. **Firebase 設定ファイルの追加**
   - Android 用：`android/app/google-services.json` を配置
   - iOS 用：`ios/Runner/GoogleService-Info.plist` を配置
   - またはプロジェクトルートで `flutterfire configure` を実行し、`lib/firebase_options.dart` を生成します。

2. **環境変数ファイル（`.env`）の追加**
   - プロジェクトルートディレクトリに `.env.example` をコピーして `.env.development` ファイルを作成します。
   ```bash
   cp .env.example .env.development
   ```
   ```env
   # バックエンドサーバー URL
   API_URL=http://localhost:8080/api

   # Gemini AI API キー
   GEMINI_API_KEY=YOUR_GEMINI_API_KEY
   ```

### 2. パッケージのインストールと起動

```bash
# 依存パッケージのインストール
flutter pub get

# アプリの起動
flutter run
```

VS Code または Android Studio のデバイスツールを使用して、お好みのエミュレーターや実機で起動することもできます。
