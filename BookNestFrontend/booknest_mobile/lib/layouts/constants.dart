import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
}

class AppColors {
  static const Color darkBrown = Color(0xFF443831);
  static const Color mediumBrown = Color(0xFF776860);
  static const Color lightBrown = Color(0xFFBAB2A7);
  static const Color pageBg = Color(0xFFD2CCC3);
}

class AppSnackBar {
  static void showError(dynamic contextOrOverlay, dynamic error) {
    final message = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Error: ', '');
    show(contextOrOverlay, message, isError: true);
  }

  static void show(
    dynamic contextOrOverlay,
    String message, {
    bool isError = false,
  }) {
    OverlayState? overlay;
    if (contextOrOverlay is BuildContext) {
      overlay = Overlay.of(contextOrOverlay);
    } else if (contextOrOverlay is OverlayState) {
      overlay = contextOrOverlay;
    }
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AppToast(
        message: message,
        isError: isError,
        onDismiss: () {
          try { entry.remove(); } catch (_) {}
        },
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      try { entry.remove(); } catch (_) {}
    });
  }
}

class _AppToast extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _AppToast({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 12,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isError
                  ? const Color(0xFF6B2D2D).withValues(alpha: 0.93)
                  : AppColors.darkBrown.withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}