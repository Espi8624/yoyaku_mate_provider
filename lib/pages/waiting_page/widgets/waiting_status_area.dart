import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../waiting_screen_viewmodel.dart';

class WaitingStatusArea extends StatelessWidget {
  const WaitingStatusArea({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WaitingScreenViewModel>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("現状ウェイティング状況",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 24),
          _StatusInfo(label: "直前入場時間", value: vm.lastEntryTimeFormatted),
          const SizedBox(height: 8),
          const _StatusInfo(label: "予想待機時間", value: "10分"),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text("現在待機チーム",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(vm.waitingCount.toString(),
                        style: const TextStyle(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: AppColors.roleManager)),
                    const SizedBox(width: 8),
                    const Text("チーム",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final String label;
  final String value;
  const _StatusInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.accentPrimary)),
      ],
    );
  }
}
