import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/constants/terms_of_service.dart';
import 'package:yoyaku_mate_provider/pages/sign_up/sign_up_viewmodel.dart';
import 'package:yoyaku_mate_provider/widgets/common_buttons/action_button.dart';

class TermsOfServiceStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onShowFullTerms;

  const TermsOfServiceStep({
    super.key,
    required this.onNext,
    required this.onShowFullTerms,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignUpViewModel>();
    final isAgreed = vm.isTermsAgreed;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('利用規約同意',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('サービス利用の為、利用規約に同意して下さい。',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  TermsOfService.content,
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onShowFullTerms,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('全文表示',
                        style: TextStyle(
                            color: AppColors.accentPrimary, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => vm.setTermsAgreed(!isAgreed),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: isAgreed,
                      activeColor: AppColors.accentPrimary,
                      onChanged: (val) => vm.setTermsAgreed(val ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('利用規約に同意します。',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          ActionButton(
            label: '次へ',
            onPressed: isAgreed
                ? () {
                    vm.saveSignUpProgress();
                    onNext();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
