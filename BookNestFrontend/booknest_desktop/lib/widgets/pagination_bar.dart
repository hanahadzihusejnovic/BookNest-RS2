import 'package:flutter/material.dart';
import '../layouts/constants.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: currentPage > 0 ? onPrevious : null,
            child: Icon(
              Icons.arrow_back,
              color: currentPage > 0
                  ? AppColors.darkBrown
                  : AppColors.darkBrown.withValues(alpha: 0.3),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${currentPage + 1}',
            style: const TextStyle(
              color: AppColors.darkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: currentPage < totalPages - 1 ? onNext : null,
            child: Icon(
              Icons.arrow_forward,
              color: currentPage < totalPages - 1
                  ? AppColors.darkBrown
                  : AppColors.darkBrown.withValues(alpha: 0.3),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
