import 'package:flutter/material.dart';
import '../layouts/constants.dart';

enum BookCardStyle {
  details,   // home, shop — DETAILS button, BoxFit.contain
  remove,    // favorites, tbr — REMOVE button, BoxFit.cover
  icons,     // category — cijena + ikonice, BoxFit.cover
  plain,     // profile My Books — samo slika/naslov/autor
}

class BookCard extends StatelessWidget {
  final String title;
  final String? author;
  final String? imageUrl;
  final BookCardStyle style;

  // Za details/remove button
  final VoidCallback? onTap;

  // Za icons style (category)
  final double? price;
  final VoidCallback? onCartTap;
  final VoidCallback? onFavTap;
  final VoidCallback? onBookmarkTap;

  // Za tbr — status label ispod autora
  final String? statusLabel;

  const BookCard({
    super.key,
    required this.title,
    this.author,
    this.imageUrl,
    this.style = BookCardStyle.details,
    this.onTap,
    this.price,
    this.onCartTap,
    this.onFavTap,
    this.onBookmarkTap,
    this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final useContain = style == BookCardStyle.details || 
                       style == BookCardStyle.icons ||
                       style == BookCardStyle.remove ||
                       style == BookCardStyle.plain;

    return GestureDetector(
      onTap: style == BookCardStyle.icons ? onTap : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.pageBg.withOpacity(0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Slika
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

            // Tekst + akcije
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
                      color: AppColors.darkBrown.withOpacity(0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // TBR status
                  if (statusLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      statusLabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkBrown.withOpacity(0.55),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Akcije ovisno o stilu
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
                          color: AppColors.darkBrown.withOpacity(0.82),
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
                  // plain — nema akcija
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.white.withOpacity(0.45),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.darkBrown.withOpacity(0.5),
        size: 28,
      ),
    );
  }
}