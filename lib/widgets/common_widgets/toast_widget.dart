import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yoyaku_mate_provider/constants/app_colors.dart';
import 'package:yoyaku_mate_provider/routes.dart';

enum ToastType { success, error, info }

class ToastWidget {
  static void show(BuildContext? context, String message,
      {ToastType type = ToastType.info}) {
    OverlayState? overlayState;

    // 1. 渡されたcontextからOverlayを探す
    if (context != null) {
      try {
        overlayState = Overlay.of(context);
      } catch (_) {
        // contextが無効、またはOverlayが見つからない場合は無視
      }
    }

    // 2. 見つからない場合、GlobalKeyからOverlayを取得 (NavigatorState.overlay)
    if (overlayState == null) {
      try {
        overlayState = rootNavigatorKey.currentState?.overlay;
      } catch (e) {
        // print("ToastWidget: Global Navigator overlay error: $e");
      }
    }

    if (overlayState == null) {
      // print("ToastWidget: Overlay not found via context or global key.");
      return;
    }

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    Key? key,
    required this.message,
    required this.type,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _ToastWidgetState createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600), // 少し滑らかに
      vsync: this,
    );

    // 上から下に落ちるアニメーション (Elastic効果)
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    _timer = Timer(const Duration(seconds: 3), () {
      _close();
    });
  }

  void _close() {
    if (_isClosing) return;
    if (!mounted) return;

    setState(() {
      _isClosing = true;
    });
    _timer?.cancel();
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (widget.type) {
      case ToastType.success:
        backgroundColor = Colors.white;
        iconColor = AppColors.accentPrimary;
        icon = Icons.check_circle_outline;
        break;
      case ToastType.error:
        backgroundColor = Colors.white;
        iconColor = AppColors.error;
        icon = Icons.highlight_off_rounded;
        break;
      case ToastType.info:
        backgroundColor = Colors.white;
        iconColor = AppColors.accentPrimary;
        icon = Icons.info_outline_rounded;
        break;
    }

    // 上部SafeArea + 余白
    final topPadding = MediaQuery.of(context).viewPadding.top + 10;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: iconColor.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border:
                      Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                          height: 1.2,
                          fontFamily: 'Pretendard', // あれば良し、なければデフォルト
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _close,
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey[400], size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
