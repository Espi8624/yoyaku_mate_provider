# 状態管理アーキテクチャの Provider(MVVM) → Riverpod + Hooks 全面移行

> 最終更新: 2026-09-01
> 関連: [ADR-001](../decisions/ADR-001-provider-state.md) (本リファクタリングにより一部の決定が上書きされました)

## 背景および問題点 (AS-IS)

初期は [ADR-001](../decisions/ADR-001-provider-state.md) の決定に基づき、`provider` パッケージ + `ChangeNotifier` による MVVM パターンで状態管理を行っていました。運用を続ける中で、以下の問題が顕在化しました。

1. **命令的なデータ取得と手動の状態同期**: `initState` で `fetchXxx()` を呼び忘れると画面が永遠に空のままになり、ローディング/エラー状態も `_isLoading`/`_errorMessage` フィールドを毎回手動で `notifyListeners()` と同期させる必要がありました。

2. **スコープと実体の不一致（"God Object"化）**: `ProfileScreenViewModel` は `pages/profile_page/` 配下にあり名前もページ専用のように見えましたが、実際には `main.dart` のルートで `ChangeNotifierProxyProvider<User?, ProfileScreenViewModel>` としてFirebase認証状態に連動する形で登録されており、ログインユーザー・所有店舗一覧・選択中店舗・店舗設定/ライセンスまでも保持するアプリ全体のセッション状態でした。`provider` パッケージでは新しいグローバルな provider を追加するたびに `main.dart` の `MultiProvider` 配線を編集する必要があり、その手間を避けるために既存の VM へ機能を継ぎ足し続けた結果、責務が肥大化していました。

3. **コンパイル時に検出できない依存漏れ**: `context.watch<T>()`/`context.read<T>()` は `T` が祖先ツリーに登録されていなければ実行時にクラッシュします。実際に `main.dart` の `MultiProvider` から `StoreSettingsService` の登録を削除した際、未移行だった `waiting_screen.dart` がそれを直接参照していたことが `flutter analyze` では検出されず、手動の `grep` で事後的に発見する事態が発生しました。

## 解決策: ページ単位での Riverpod + Hooks への段階的移行 (TO-BE)

[enechain技術ブログのMVVM→宣言的アーキテクチャ事例](https://techblog.enechain.com/entry/flutter-rearchitecture-from-mvvm) を参考に、`hooks_riverpod` + `riverpod_annotation`/`riverpod_generator`(codegen, `.g.dart` はGitにコミット) を採用し、既存の `provider` ツリーと新しい `ProviderScope` を共存させながらページ単位で順次移行しました。

### 設計原則

| 原則 | 内容 |
|------|------|
| スコープの分離 | ページローカル状態は `lib/pages/xxx/xxx_providers.dart`、アプリ全体のセッション状態(ログインユーザー/所有店舗/選択店舗/店舗設定・ライセンス)は新設した [lib/providers/session_providers.dart](../../lib/providers/session_providers.dart) に集約 |
| Ephemeral UI状態 | `StatefulWidget` の代わりに `flutter_hooks` の `useState`/`useTabController`/`useAppLifecycleState` などを使用 |
| 非同期状態の表現 | `AsyncValue`/`FutureProvider`/`AsyncNotifier` で ローディング/エラー/データ を宣言的に表現し、`_isLoading`/`_errorMessage` の手動フィールドを撤廃 |
| 更新後の再取得 | 成功時は `ref.invalidate(...)` の1行で宣言的に再取得（Riverpodは再取得中も直前のデータを保持するため、フルスクリーンのちらつきが起きない） |
| 成功/失敗の通知 | アクション用 Notifier は状態を持たず(`build() {}`)、失敗時は単に `rethrow`。呼び出し元（画面側）が即座に Toast/SnackBar を表示 |

### Before / After の一例（`menu_management_page`）

```dart
// AS-IS: ChangeNotifier + 手動フィールド同期
class MenuManagementScreenViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<MenuListItem> _menuItems = [];

  Future<void> loadMenuData(String storeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _menuItems = await _menuService.fetchMenuItems(storeId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

```dart
// TO-BE: AsyncNotifier + codegen — ローディング/エラーはAsyncValueが自動表現
@riverpod
class MenuItemsNotifier extends _$MenuItemsNotifier {
  @override
  Future<MenuManagementData> build({required String storeId}) async {
    final service = ref.watch(menuServiceProvider);
    final items = await service.fetchMenuItems(storeId);
    return MenuManagementData.recompute(items);
  }
}

// 呼び出し側
final menuAsync = ref.watch(menuItemsNotifierProvider(storeId: storeId));
// menuAsync.isLoading / menuAsync.hasError / menuAsync.valueOrNull で判定
```

## 移行順序と各ページの要点

| # | ページ / 対象 | 特記事項 |
|---|------|------|
| 1 | `staff_management_page` | パイロット。基本パターン（`xxx_providers.dart` + `AsyncNotifier` + Actions）を確立 |
| 2 | `profile_page` + セッション状態 | `ProfileScreenViewModel` を全面解体し `session_providers.dart` へ移設。`StoreSelectionViewModel`（薄いラッパー）も同時撤去。`store_selection`/`sign_up_page.dart`/`navigation_bar.dart`/`add_store_page.dart` も追随して移行 |
| 3 | `menu_management_page` | カテゴリ/メニュー一覧を1つの不変データクラスに統合。1秒デバウンス自動保存は Notifier インスタンスフィールドの `Timer?` + `ref.onDispose` で実装。`TabController` はカテゴリ数変化に応じた再生成が必要なため Hooks 化せず `ConsumerState` + `ref.listen` を維持 |
| 4 | `statistics_page` | フィルタ状態(期間/指標/日付)は `useState`(Hooks)、実データ取得は `(storeId, period, date)` を引数にした `FutureProvider.family` という **Hooksと Riverpod のハイブリッド設計** を初適用。副次効果として、閲覧済み期間へ戻った際にfamilyキャッシュにより再取得なしで即表示されるようになった |
| 5 | `waiting_page` | 最も複雑な移行対象（SSEポーリングストリーム、楽観的更新の衝突防止フラグ、アプリライフサイクル監視、重複ログイン検知）。`WidgetsBindingObserver` は `flutter_hooks` の `useAppLifecycleState()` + `useEffect` に置換。店舗の待機ポリシー(`estimatedWaitTime`等)は独自に再取得せず `session_providers.dart` の `storeSettingsProvider` を再利用し、重複API呼び出しを削減 |
| 6 | `sign_up` | `provider` パッケージのアプリ全体で最後の使用箇所。Firebase Authの電話番号認証コールバック（`verifyPhoneNumber` の `verificationCompleted`/`verificationFailed`/`codeSent`）がウィジェット破棄後にも非同期発火し得る問題への対処が焦点。移行完了に伴い `pubspec.yaml` から `provider` パッケージそのものを削除 |

## 実装上の注意点（今後の参考用）

- **`ref.mounted` は riverpod 2.6.1に存在しない**: Notifier の dispose 後の書き込みガードには `ref.onDispose(() => _isDisposed = true)` で立てた自前フラグを、全ての状態更新が通るヘルパー関数内でチェックする方式を用いた（`ChangeNotifier.notifyListeners()` オーバーライドによる `_isDisposed` チェックの直接的な置き換え）。
- **既存のグローバル `Provider<T>` 登録を削除する前は必ず `grep` で全体の参照箇所を再確認する**: `flutter analyze` では検出できないランタイム限定の依存漏れが発生し得る（`waiting_screen.dart` での実例）。
- **ページフォルダに `xxx_providers.dart` が無いのは正常な場合がある**: そのページが所有するローカル状態が無く（全てセッション状態、または Hooks で完結する場合）、無理に空のファイルを作る必要はない（例: `profile_page/`）。
- **既存の些細な仕様上の癖は移行時に無断で修正しない**: 例えば `menu_management_page` の「`addCategory` で作った空カテゴリは他の操作後に消える」という挙動は、アーキテクチャ移行のみが目的であるため意図的にそのまま踏襲した。

## 期待される効果

1. **依存漏れのコンパイル時検出**: `ref.watch`/`ref.read` は対象 provider が存在しなければビルド自体が失敗するため、`waiting_screen.dart` のようなランタイムクラッシュが構造的に起こりにくくなった。
2. **ボイラープレートの削減**: `_isLoading`/`_errorMessage` の手動同期が不要になり、`AsyncValue` が宣言的にローディング/エラー/データを表現する。
3. **スコープの明確化**: ページローカル状態とアプリ全体のセッション状態が物理的に別ファイルに分離され、`ProfileScreenViewModel` のような "隠れたグローバル状態" が再発しにくい構造になった。
4. **依存パッケージの整理**: `provider` パッケージへの依存を `pubspec.yaml` から完全に除去し、状態管理を Riverpod 一本化した。

## 関連ドキュメント

- [ADR-001: 状態管理ツールとしての Provider パターンの採用](../decisions/ADR-001-provider-state.md)（本リファクタリングにより上書きされました）
- [アーキテクチャの概要](../implementation/architecture.md)
