import 'package:flutter/material.dart';
import '../layouts/constants.dart';

class BookFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? error;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const BookFormField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.error,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: error != null ? Colors.red.shade300 : Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.lightBrown.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? Colors.red.shade300 : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? Colors.red.shade300 : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBrown),
        ),
        errorText: error,
        errorStyle: TextStyle(color: Colors.red.shade300, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

class BookFormDropdownTrigger extends StatelessWidget {
  final LayerLink link;
  final String hint;
  final String? selectedLabel;
  final bool isOpen;
  final String? error;
  final bool loading;
  final VoidCallback onTap;

  const BookFormDropdownTrigger({
    super.key,
    required this.link,
    required this.hint,
    required this.isOpen,
    required this.onTap,
    this.selectedLabel,
    this.error,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: link,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: error != null ? Colors.red.shade300 : Colors.transparent,
                ),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.lightBrown, strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedLabel ?? hint,
                            style: TextStyle(
                              color: selectedLabel != null
                                  ? Colors.white
                                  : error != null
                                      ? Colors.red.shade300
                                      : Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: AppColors.lightBrown,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!,
              style: TextStyle(fontSize: 11, color: Colors.red.shade300)),
        ],
      ],
    );
  }
}
