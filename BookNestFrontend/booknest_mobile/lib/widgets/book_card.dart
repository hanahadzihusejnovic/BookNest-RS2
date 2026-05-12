import 'package:flutter/material.dart';
import '../layouts/constants.dart';

enum BookCardStyle {
  details,
  remove,
  icons,
  plain,
}

class BookCard extends StatelessWidget {
  final String title;
  final String? author;
  final String? imageUrl;
  final BookCardStyle style;
  final String? reason;

  final VoidCallback? onTap;

  final double? price;
  final VoidCallback? onCartTap;
  final VoidCallback? onFavTap;
  final VoidCallback? onBookmarkTap;

  final String? statusLabel;

  const BookCard({
    super.key,
    required this.title,
    this.author,
    this.imageUrl,
    this.style = BookCardStyle.details,
    this.reason,
    this.onTap,
    this.price,
    this.onCartTap,
    this.onFavTap,
    this.onBookmarkTap,
    this.statusLabel,
  });

  void _showReason(BuildContext context) {
    AppSnackBar.show(context, reason!);
  }

  @override
  Widget build(BuildContext context) {
    final useContain = style == BookCardStyle.details ||
                       style == BookCardStyle.icons ||
                       style == BookCardStyle.remove ||
                       style == BookCardStyle.plain;

    return GestureDetector(
      onTap: style == BookCardStyle.icons ? onTap : null,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            decoration: BoxDecoration(
              color: AppColors.pageBg.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: double.infinity,
                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? Image.network(
                              imageUrl!,
                              fit: useContain ? BoxFit.contain : BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallback(),
                            )
                          : _fallback(),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        author ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.darkBrown.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      if (statusLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          statusLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.darkBrown.withValues(alpha: 0.55),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],

                      const Spacer(),

                      if (style == BookCardStyle.details)
                        SizedBox(
                          width: double.infinity,
                          height: 22,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.darkBrown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'DETAILS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                      if (style == BookCardStyle.remove)
                        SizedBox(
                          width: double.infinity,
                          height: 22,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.darkBrown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'REMOVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                      if (style == BookCardStyle.icons) ...[
                        if (price != null)
                          Text(
                            '${price!.toStringAsFixed(2)} BAM',
                            style: TextStyle(
                              color: AppColors.darkBrown.withValues(alpha: 0.82),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: onCartTap,
                              child: Icon(Icons.shopping_cart_outlined,
                                  size: 12, color: AppColors.darkBrown),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: onFavTap,
                              child: Icon(Icons.favorite_border,
                                  size: 12, color: AppColors.darkBrown),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: onBookmarkTap,
                              child: Icon(Icons.menu_book,
                                  size: 12, color: AppColors.darkBrown),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Info ikonica — prikazuje se samo kad postoji reason
          if (reason != null && reason!.isNotEmpty)
            Positioned(
              top: 4,
              right: 8,
              child: GestureDetector(
                onTap: () => _showReason(context),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.darkBrown,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.white.withValues(alpha: 0.45),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.darkBrown.withValues(alpha: 0.5),
        size: 28,
      ),
    );
  }
}