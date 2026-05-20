import 'package:flutter/material.dart';
import '../layouts/constants.dart';

class AppDropdown<T> extends StatefulWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) labelFn;
  final ValueChanged<T?>? onChanged;
  final String? error;

  const AppDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.labelFn,
    required this.onChanged,
    this.error,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _open() {
    if (widget.items.isEmpty || widget.onChanged == null) return;

    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 200.0;

    _overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox(),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 46),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: width,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppColors.darkBrown,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => Divider(
                      color: AppColors.pageBg.withValues(alpha: 0.25),
                      height: 1,
                      thickness: 1,
                      indent: 14,
                      endIndent: 14,
                    ),
                    itemBuilder: (context, i) {
                      final item = widget.items[i];
                      final isSelected = item == widget.value;
                      return InkWell(
                        onTap: () {
                          _close();
                          widget.onChanged?.call(item);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Text(
                            widget.labelFn(item).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.pageBg,
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.w500,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.error != null;
    final bool hasValue = widget.value != null;
    final bool enabled = widget.onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: enabled ? _toggle : null,
            child: Container(
              key: _triggerKey,
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: hasError
                        ? Colors.red
                        : AppColors.darkBrown,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasValue
                          ? widget.labelFn(widget.value as T)
                          : widget.hint,
                      style: TextStyle(
                        color: hasValue
                            ? AppColors.darkBrown
                            : hasError
                                ? Colors.red
                                : AppColors.darkBrown,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: hasError
                        ? Colors.red
                        : AppColors.darkBrown
                            .withValues(alpha: enabled ? 1.0 : 0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.error!,
            style: const TextStyle(fontSize: 11, color: Colors.red),
          ),
        ],
      ],
    );
  }
}
