import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

// 一括翻訳の進捗 (完了ステップ数 / 全ステップ数)
typedef TranslationProgress = ({int done, int total});

// 一括翻訳の進捗ダイアログ。
// 途中でメニューデータを触られると不整合になるため、バリアタップ・戻る操作では閉じない。
// 進捗は ValueListenable 経由で受け取り、バー部分だけを再構築する
class TranslationProgressDialog extends StatelessWidget {
  final ValueListenable<TranslationProgress> progress;
  final String title;
  final String description;

  const TranslationProgressDialog({
    super.key,
    required this.progress,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColors.cardBackground,
        insetPadding: const EdgeInsets.all(24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<TranslationProgress>(
                  valueListenable: progress,
                  builder: (context, value, _) =>
                      _ProgressBody(progress: value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 進捗バーと件数表示。進捗更新のたびに再構築されるのはこの部分だけ
class _ProgressBody extends StatelessWidget {
  final TranslationProgress progress;

  const _ProgressBody({required this.progress});

  @override
  Widget build(BuildContext context) {
    // 総数が未確定(0)の間は不定形バーを表示する
    final ratio = progress.total > 0 ? progress.done / progress.total : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progress.total > 0
              ? '${progress.done} / ${progress.total}'
              : '準備中...',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
