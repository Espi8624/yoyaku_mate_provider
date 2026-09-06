# トラブルシューティング: 無彩色をシードにした ColorScheme が青緑になる

> 作成日: 2026-09-06
> 関連文書: [シフト表実装詳細書](../implementation/shift-table.md)

---

## 症状

色を明示していないウィジェットが、アプリのデザイン(黒〜グレー基調)と無関係な**青緑色**で描画されていた。

* `修正依頼 N件` の `OutlinedButton`(文字と枠線)
* 衝突解決ダイアログの `OutlinedButton` / `TextButton`
* 削除中に出る `CircularProgressIndicator`
* `Switch`、ドロップダウンのハイライト、テキスト選択のハンドル など

個別に色を指定していない箇所だけに出るため、最初は「指定漏れ」に見えたが、該当箇所が広範囲に散らばっていた。

---

## 原因

`main.dart` のテーマ定義。

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: AppColors.accentPrimary,  // #2C2C2C
),
```

`AppColors.accentPrimary` は `#2C2C2C` という**ほぼ無彩色**。Material 3 の `fromSeed` はシード色を HCT 色空間に変換し、そこから**色相 (hue) を取り出して**トーナルパレットを生成する。無彩色は色相が定義されないため任意の値が採用され、そこに既定の彩度が足される。

結果として `colorScheme.primary` が **`#006874`(青緑)** になっていた。M3 で黒やグレーをシードに渡すと青緑が出るのは既知の落とし穴。

`primary` は色を明示していないウィジェットの既定色として広く参照されるため、指定漏れの箇所すべてがこの青緑を拾っていた。

---

## 対処

彩度を落とすバリアントを指定した上で、実際に画面へ出るロールを `AppColors` で直接上書きした。

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: AppColors.accentPrimary,
  dynamicSchemeVariant: DynamicSchemeVariant.neutral,
).copyWith(
  primary: AppColors.accentPrimary,
  onPrimary: AppColors.textPrimaryLight,
  secondary: AppColors.accentSecondary,
  onSecondary: AppColors.textPrimaryLight,
  surface: AppColors.cardBackground,
  onSurface: AppColors.textPrimary,
  tertiary: AppColors.accentSecondary,
  onTertiary: AppColors.textPrimaryLight,
  error: AppColors.error,
  onError: AppColors.textPrimaryLight,
  outline: AppColors.border,
  surfaceTint: AppColors.accentPrimary,
),
```

### `surfaceTint` を忘れないこと

`neutral` バリアントを指定しても `surfaceTint` は `#516164` と青緑寄りのまま残る。M3 はこの色で **elevation のある Card / Dialog / Menu の背景を着色する**ため、指定しないとダイアログにうっすら青緑が乗る。

### 全ロールを明示しない理由

`primaryContainer` や `secondaryContainer` は上書きしていない。アプリ内の `Chip` / `ChoiceChip` / `ActionChip` はいずれも `backgroundColor` / `selectedColor` を直接指定しており、これらのロールを消費していないため。全ロールを書き下すと M3 内部の整合性(コントラスト比の担保など)が崩れるので、**画面に出るロールだけを上書きする**方針とした。

---

## 検証方法

`ColorScheme` の各ロールの彩度(RGB の max-min)を出力して確認した。修正後、画面に出るロールはすべて彩度 0 になっている。

| ロール | 修正前 | 修正後 |
|---|---|---|
| `primary` | `#006874` | `#2C2C2C` |
| `secondary` | `#4A6267` | `#424242` |
| `surfaceTint` | `#516164` | `#2C2C2C` |
| `outline` | `#6F797A` | `#EAEAEA` |

---

## 教訓

* **無彩色をデザインの基調にしているアプリで `ColorScheme.fromSeed` をそのまま使ってはいけない。** シードから色相を復元できないため、意図しない色相が混入する。
* 「色を指定していない箇所」は思っているより多い。テーマの既定色は必ず一度実際の値を出力して確認する。
* `surfaceTint` は `primary` と別のロールなので、`primary` を上書きしただけでは追随しない。
