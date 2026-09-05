import 'package:flutter/material.dart';

class AppColors {
  // --- 基本パレット ---

  /// 背景色
  static const Color background = Color(0xFFF5F7FA);

  /// 基本ブラック
  static const Color primaryBlack = Color(0xFF161616);
  static const Color primary = primaryBlack; // Alias
  static const Color shadow = Color(0xFF000000);

  // --- アクセント & インタラクティブパレット ---

  /// メインアクセント
  static const Color accentPrimary = Color(0xFF2C2C2C);

  /// セカンダリアクセント
  static const Color accentSecondary = Color(0xFF424242);

  // --- テキスト & コンテンツパレット ---

  /// メインテキスト
  static const Color textPrimary = Color(0xFF161616);

  /// 暗い背景上のテキスト
  static const Color textPrimaryLight = Color(0xFFF8F9FA);

  /// セカンダリテキスト: 重要度の低い情報に使う中間グレー。
  static const Color textSecondary = Color(0xFF6E6E6E);

  /// ターシャリテキスト: プレースホルダーなどに使う薄いグレー。
  static const Color textTertiary = Color(0xFFA6A6A6);

  // --- UI & ユーティリティパレット ---

  /// カード背景
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// ボーダーと区切り線
  static const Color border = Color(0xFFEAEAEA);

  /// 無効化要素
  static const Color disabled = Color(0xFFDCDCDC);

  /// 無効化背景
  static const Color disabledBackground = Color(0xFFF0F0F0);

  // --- セマンティックパレット ---

  /// エラー
  static const Color error = Color(0xFFC53030);

  /// 警告
  static const Color warning = Color(0xFFDD6B20);

  /// 成功
  static const Color success = Color(0xFF2F855A);

  // --- ロールカラー ---

  /// マネージャー
  static const Color roleManager = Color(0xFF8B572A);

  /// スタッフ
  static const Color roleStaff = Color(0xFF5A677D);

  // 状態管理色
  static const Color pendingBackground = Color(0xFFFFF3E0);
  static const Color pending = Color(0xFFF57C00);

  static const Color approvedBackground = Color(0xFFE8F5E9);
  static const Color approved = Color(0xFF388E3C);

  static const Color rejectedBackground = Color(0xFFFFEBEE);
  static const Color rejected = Color(0xFFD32F2F);

  static const Color notSubmittedBackground = Color(0xFFEEEEEE);
  static const Color notSubmitted = Color(0xFF616161);

  // --- シフト表パレット ---

  /// シフトブロック用の配色。スタッフごとにインデックスで循環割り当てし、
  /// 週間シフト表グリッド上で誰の枠かを視覚的に区別する
  static const List<Color> shiftBlockPalette = [
    Color(0xFF5B8DEF), // 青
    Color(0xFF4CAF93), // 緑
    Color(0xFFB080E0), // 紫
    Color(0xFFE0954F), // 橙
    Color(0xFFE0709E), // 桃
    Color(0xFF4FADC7), // 青緑
  ];

  /// 同時間帯に複数人重なった際にまとめて表示するカード用の配色。
  /// shiftBlockPalette(個人ごとの色)とは独立した色群で、特定の誰かの色と
  /// 混同されないよう彩度を抑えたトーンにしている。メンバー構成のハッシュ値で
  /// インデックスを選ぶため、同じ組み合わせは常に同じ色、組み合わせが変われば
  /// 別の色になり、単一の固定色で埋め尽くされるのを防ぐ
  static const List<Color> groupShiftBlockPalette = [
    Color(0xFF56637A), // スレート
    Color(0xFF7A5C56), // ブラウン
    Color(0xFF5C7A6C), // オリーブグリーン
    Color(0xFF6C5C7A), // プラム
    Color(0xFF7A6C56), // カーキ
  ];

  // --- 統計・チャートパレット ---
  // statistics_screen / dynamic_chart_card 専用。ダークカード上での視認性を
  // 優先した配色のため、上記セマンティックパレット(success/error等)とは別に管理する。

  /// 強調テキスト・当日データのバー色
  static const Color statChartDark = Color(0xFF212529);

  /// 補助テキスト・前回データのラベル色
  static const Color statChartMuted = Color(0xFF868E96);

  /// チャート軸ラベル(より薄いグレー)
  static const Color statAxisLabel = Color(0xFFADB5BD);

  /// セクションタイトル
  static const Color statSectionTitle = Color(0xFF343A40);

  /// キャンセル関連の強調色
  static const Color statDangerRed = Color(0xFFFA5252);
  static const Color statDangerRedBg = Color(0xFFFFF5F5);

  /// No-Show関連の強調色・前回チャートライン
  static const Color statAlertRed = Color(0xFFFF6B6B);

  /// 平均待ち時間アイコン色
  static const Color statIndigo = Color(0xFF4C6EF5);
  static const Color statIndigoBg = Color(0xFFE7F5FF);

  /// 指標選択タブのトラック背景
  static const Color statTabTrackBg = Color(0xFFEFF0F3);

  /// 来店者数カードのダークグラデーション
  static const Color statDarkCardGradientStart = Color(0xFF2E2E2E);
  static const Color statDarkCardGradientEnd = Color(0xFF1A1A1A);

  /// 前週比の増減バッジ
  static const Color statPositiveBg = Color(0xFF1B4D3E);
  static const Color statNegativeBg = Color(0xFF4A1B1B);
  static const Color statPositiveGreen = Color(0xFF4CD964);
  static const Color statNegativeRed = Color(0xFFFF3B30);

  // --- コンポーネント専用色 ---

  /// トーストメッセージのテキスト色
  static const Color toastText = Color(0xFF333333);

  /// QRスキャナーのカットアウト外側を覆う半透明オーバーレイ(黒 31%)
  static const Color qrScannerOverlay = Color(0x50000000);
}
