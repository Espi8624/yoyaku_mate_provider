import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

// 純粋な表示ウィジェット。待機件数などはRiverpodを直接見ずに親から受け取る
// (WaitingListPanelと同じ方針)。展開/縮小のみページローカルなephemeral UI状態
// のためHookWidgetのuseStateで管理する。
class WaitingStatusArea extends HookWidget {
  final bool isInitiallyExpanded;
  final int waitingCount;
  final String lastEntryTimeFormatted;
  final String totalEstimatedWaitTimeFormatted;

  const WaitingStatusArea({
    super.key,
    this.isInitiallyExpanded = false,
    required this.waitingCount,
    required this.lastEntryTimeFormatted,
    required this.totalEstimatedWaitTimeFormatted,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(isInitiallyExpanded);
    final isMobile = MediaQuery.of(context).size.width < 700;

    // mobile layoutで拡張/縮小ステータスをtoggle
    void toggleExpansion() {
      if (isMobile) {
        isExpanded.value = !isExpanded.value;
      }
    }

    // desktopの場合
    if (!isMobile) {
      return _buildDesktopExpandedContent();
    }

    // mobileでは拡張/縮小ステータスによって適切なUIを表示
    return GestureDetector(
      onTap: toggleExpansion,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstChild: _buildCollapsedContent(),
        secondChild: _buildMobileExpandedContent(),
        crossFadeState: isExpanded.value
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
      ),
    );
  }

  // mobile縮小UI
  Widget _buildCollapsedContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("現状ウェイティング状況",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(waitingCount.toString(),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.roleManager)),
                const SizedBox(width: 8),
                const Text("チーム",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // desktop拡張UI
  Widget _buildDesktopExpandedContent() {
    return Container(
      height: double.infinity,
      // Padding removed from here to allow different widths
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(2, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max, // Changed to max to fill height
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("現状ウェイティング状況",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 16),
                _StatusInfo(label: "直前入場時間", value: lastEntryTimeFormatted),
                const SizedBox(height: 8),
                _StatusInfo(
                    label: "予想待機時間", value: totalEstimatedWaitTimeFormatted),
              ],
            ),
          ),
          const Spacer(), // Pushes the bottom info to the bottom
          Padding(
            padding: const EdgeInsets.all(12), // Reduced padding for wider card
            child: _buildBottomInfo(),
          ),
        ],
      ),
    );
  }

  // mobile拡張UI
  Widget _buildMobileExpandedContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 30), // 影が切れないように余白を確保
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.25), // くっきり見えるように調整
                blurRadius: 24,
                offset: const Offset(0, -8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("現状ウェイティング状況",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 24),
            _StatusInfo(label: "直前入場時間", value: lastEntryTimeFormatted),
            const SizedBox(height: 8),
            _StatusInfo(
                label: "予想待機時間", value: totalEstimatedWaitTimeFormatted),
            const SizedBox(height: 24),
            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Text("現在待機チーム",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                waitingCount.toString(),
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: AppColors.roleManager,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "チーム",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.accentPrimary,
          ),
        ),
      ],
    );
  }
}
