import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class SignUpCompletePage extends StatelessWidget {
  const SignUpCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/line_icon.png', height: 80), // LINEアイコン
              const SizedBox(height: 32),
              const Text(
                'LINEアプリを確認してください!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'LINEで確認メッセージを送信しました。\nLINEアプリで承諾のボタンを押すと手続きが完了されます。',
                style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  // ログインページに移動
                  // Navigator.of(context).pop();
                  GoRouter.of(context).push('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: AppColors.textPrimaryLight,
                ),
                child: const Text('確認'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
