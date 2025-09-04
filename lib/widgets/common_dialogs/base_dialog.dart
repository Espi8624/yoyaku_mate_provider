import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';

class BaseDialog extends StatefulWidget {
  final String title;
  final Widget content;
  final double? width;

  const BaseDialog({
    super.key,
    required this.title,
    required this.content,
    this.width,
  });

  @override
  State<BaseDialog> createState() => _BaseDialogState();
}

class _BaseDialogState extends State<BaseDialog> {
  late final ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // スクロール位置を確認し、_isScrolledステータスを更新
  void _onScroll() {
    // 現在スクロール位置が(0)ではない場合true
    final bool currentlyScrolled = _scrollController.offset > 0;
    // ステータス変更が感知された場合だけsetStateを呼出し、不要なリビルドを防止
    if (currentlyScrolled != _isScrolled) {
      setState(() {
        _isScrolled = currentlyScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16.0),
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.width ?? 600,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: AppColors.cardBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AnimatedContainerで影が自然に出入りするようにする
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      boxShadow: [
                        // _isScrolledがtrueの場合のみ影を適用
                        if (_isScrolled)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close,
                                color: AppColors.textPrimary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // スクロール可能なコンテンツエリア
                  Flexible(
                    child: SingleChildScrollView(
                      // SingleChildScrollViewにScrollControllerを繋げる
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: widget.content,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
