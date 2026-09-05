import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// ミニカードの状態トーン。背景色だけを規定し、
/// 中身のレイアウトは呼び出し側が自由に組む(AppColorsの状態管理色と対応させる)
enum MiniCardTone {
  /// 承認待ち・未対応など、注意を引きたい状態
  pending,

  /// 承認済み・対応済みなど、ポジティブな状態
  approved,

  /// 却下など、ネガティブな状態
  rejected,

  /// 未提出など、まだ動きが無い状態
  notSubmitted,

  /// 特に強調しない中立な状態(デフォルト)
  neutral,
}

/// トーンごとの基準色(バッジの文字色として使う)。
/// 背景色は用途によって濃淡が違いすぎるため、ここでは一本化せず個別に定義する
extension MiniCardToneColor on MiniCardTone {
  Color get accentColor => switch (this) {
        MiniCardTone.pending => AppColors.pending,
        MiniCardTone.approved => AppColors.approved,
        MiniCardTone.rejected => AppColors.rejected,
        MiniCardTone.notSubmitted => AppColors.notSubmitted,
        MiniCardTone.neutral => AppColors.textTertiary,
      };

  Color get backgroundColor => switch (this) {
        MiniCardTone.pending => AppColors.pendingBackground,
        MiniCardTone.approved => AppColors.approvedBackground,
        MiniCardTone.rejected => AppColors.rejectedBackground,
        MiniCardTone.notSubmitted => AppColors.notSubmittedBackground,
        MiniCardTone.neutral => AppColors.disabledBackground,
      };
}

/// リスト内の1件を軽く強調して見せるための共通ミニカード枠。
/// プロジェクトのデザイン言語に合わせ、枠線は使わず背景色の濃淡だけで区別する。
/// 背景色・角丸・余白のみを規定し、中身(テキスト配置やアイコン等)は
/// 各呼び出し側が child で自由に組む
class MiniStatusCard extends StatelessWidget {
  final MiniCardTone tone;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const MiniStatusCard({
    super.key,
    this.tone = MiniCardTone.neutral,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: tone.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// カード右上などに置く、状態を一言で表す小さなテキストバッジ。
/// 色は MiniStatusCard と同じ tone から取るため、カードの色とバッジの文字色が
/// 常に対応関係を保つ(片方だけ変更して食い違う、という事故を防ぐ)
class MiniStatusBadge extends StatelessWidget {
  final MiniCardTone tone;
  final String label;

  const MiniStatusBadge({
    super.key,
    required this.tone,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontSize: 11, color: tone.accentColor),
    );
  }
}
