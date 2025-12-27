import 'package:flutter/material.dart';

class AppColors {
  // --- 基本パレット ---

  /// 背景色
  static const Color background = Color(0xFFF8F9FA);

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
}
