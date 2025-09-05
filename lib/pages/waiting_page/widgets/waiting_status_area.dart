import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/pages/waiting_page/waiting_screen_viewmodel.dart';

class WaitingStatusArea extends StatefulWidget {
  final bool isInitiallyExpanded;
  const WaitingStatusArea({super.key, this.isInitiallyExpanded = false});

  @override
  State<WaitingStatusArea> createState() => _WaitingStatusAreaState();
}

class _WaitingStatusAreaState extends State<WaitingStatusArea> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isInitiallyExpanded;
  }

  // mobile layoutで拡張/縮小ステータスをtoggle
  void _toggleExpansion() {
    if (MediaQuery.of(context).size.width < 700) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WaitingScreenViewModel>();
    final isMobile = MediaQuery.of(context).size.width < 700;

    // desktopの場合
    if (!isMobile) {
      return _buildDesktopExpandedContent(vm);
    }

    // mobileでは拡張/縮小ステータスによって適切なUIを表示
    return GestureDetector(
      onTap: _toggleExpansion,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        firstChild: _buildCollapsedContent(vm),
        secondChild: _buildMobileExpandedContent(vm),
        crossFadeState:
            _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      ),
    );
  }

  // mobile縮小UI
  Widget _buildCollapsedContent(WaitingScreenViewModel vm) {
    return Container(
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
              Text(vm.waitingCount.toString(),
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
    );
  }

  // desktop拡張UI
  Widget _buildDesktopExpandedContent(WaitingScreenViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("現状ウェイティング状況",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _StatusInfo(label: "直前入場時間", value: vm.lastEntryTimeFormatted),
            const SizedBox(height: 8),
            const _StatusInfo(label: "予想待機時間", value: "10分"),
            const SizedBox(height: 16),
            _buildBottomInfo(vm),
          ],
        ),
      ),
    );
  }

  // mobile拡張UI
  Widget _buildMobileExpandedContent(WaitingScreenViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryBlack,
              blurRadius: 12,
              offset: Offset(0, -4))
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
          _StatusInfo(label: "直前入場時間", value: vm.lastEntryTimeFormatted),
          const SizedBox(height: 8),
          const _StatusInfo(label: "予想待機時間", value: "10分"),
          const SizedBox(height: 24),
          _buildBottomInfo(vm),
        ],
      ),
    );
  }

  Widget _buildBottomInfo(WaitingScreenViewModel vm) {
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
                vm.waitingCount.toString(),
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
