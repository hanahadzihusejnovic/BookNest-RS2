import 'package:flutter/material.dart';
import '../models/book.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../services/review_service.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../services/tbr_service.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  int _quantity = 1;
  bool _descExpanded = false;
  bool _authorExpanded = false;
  final _reviewService = ReviewService();
  final _favoriteService = FavoriteService();
  final _tbrService = TBRService();
  List<BookReview> _reviews = [];
  double _averageRating = 0;
  bool _isInTBR = false;
  ReadingStatus? _tbrStatus;
  bool _isLoadingFav = false;
  bool _isLoadingTBR = false;

  @override
  void initState() {
    super.initState();
    _reviews = widget.book.reviews;
    _averageRating = widget.book.averageRating ?? 0;
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    final isInTBR = await _tbrService.isBookInTBR(widget.book.id);
    if (isInTBR) {
      final status = await _tbrService.getTBRStatus(widget.book.id);
      if (mounted) {
        setState(() {
          _isInTBR = true;
          _tbrStatus = status;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isInTBR = false;
          _tbrStatus = null;
        });
      }
    }
  }

  Future<void> _addToFavorites() async {
    setState(() => _isLoadingFav = true);
    try {
      await _favoriteService.addToFavorites(widget.book.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to favorites!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoadingFav = false);
    }
  }

  void _showTBRMenu(BuildContext buttonContext) {
    final RenderBox button =
        buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<ReadingStatus>(
      context: buttonContext,
      position: position,
      color: AppColors.pageBg,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: ReadingStatus.values.map((status) {
        final isSelected = _tbrStatus == status;
        return PopupMenuItem<ReadingStatus>(
          value: status,
          child: Center(
            child: Text(
              status.label,
              style: TextStyle(
                color: AppColors.darkBrown,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    ).then((selected) async {
      if (selected == null) return;

      if (_isInTBR && _tbrStatus != selected) {
        final confirm = await _showChangeStatusDialog(selected);
        if (!confirm) return;
      }

      setState(() => _isLoadingTBR = true);
      try {
        if (_isInTBR) {
          await _tbrService.updateTBRStatus(widget.book.id, selected);
        } else {
          await _tbrService.addToTBR(widget.book.id, selected);
        }
        setState(() {
          _isInTBR = true;
          _tbrStatus = selected;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added to TBR as "${selected.label}"!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoadingTBR = false);
      }
    });
  }

  Future<bool> _showChangeStatusDialog(ReadingStatus newStatus) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.pageBg,
          title: Text(
            'Change reading status',
            style: TextStyle(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Are you sure you want to change your reading status to "${newStatus.label}"?',
            style: TextStyle(
              color: AppColors.darkBrown.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  Text('No', style: TextStyle(color: AppColors.darkBrown)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBrown),
              child:
                  const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  void _showAddReviewDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.pageBg,
              title: Text(
                'Add a review',
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating',
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedRating = i + 1),
                        child: Icon(
                          i < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.darkBrown,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comment (optional)',
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your review...',
                      hintStyle: TextStyle(
                        color: AppColors.darkBrown.withOpacity(0.4),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.darkBrown),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _reviewService.addReview(
                              bookId: widget.book.id,
                              rating: selectedRating,
                              comment: commentController.text.isEmpty
                                  ? null
                                  : commentController.text,
                            );

                            final reviews = await _reviewService
                                .getBookReviews(widget.book.id);
                            final avg = reviews.isEmpty
                                ? 0.0
                                : reviews
                                        .map((r) => r.rating)
                                        .reduce((a, b) => a + b) /
                                    reviews.length;

                            setState(() {
                              _reviews = reviews;
                              _averageRating = avg;
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Review added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdateReviewDialog(BookReview review) {
    int selectedRating = review.rating;
    final commentController =
        TextEditingController(text: review.comment ?? '');
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.pageBg,
              title: Text(
                'Update your review',
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating',
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedRating = i + 1),
                        child: Icon(
                          i < selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.darkBrown,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Comment (optional)',
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: TextStyle(
                        color: AppColors.darkBrown, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Write your review...',
                      hintStyle: TextStyle(
                        color: AppColors.darkBrown.withOpacity(0.4),
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: TextStyle(color: AppColors.darkBrown)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _reviewService.updateReview(
                              reviewId: review.id,
                              rating: selectedRating,
                              comment: commentController.text.isEmpty
                                  ? null
                                  : commentController.text,
                            );

                            final reviews = await _reviewService
                                .getBookReviews(widget.book.id);
                            final avg = reviews.isEmpty
                                ? 0.0
                                : reviews
                                        .map((r) => r.rating)
                                        .reduce((a, b) => a + b) /
                                    reviews.length;

                            setState(() {
                              _reviews = reviews;
                              _averageRating = avg;
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Review updated!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBrown),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Update',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteReviewDialog(BookReview review) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.pageBg,
          title: Text(
            'Delete review',
            style: TextStyle(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Do you want to delete your review and rating?',
            style: TextStyle(
              color: AppColors.darkBrown.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('No', style: TextStyle(color: AppColors.darkBrown)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _reviewService.deleteReview(review.id);

                  final reviews = await _reviewService
                      .getBookReviews(widget.book.id);
                  final avg = reviews.isEmpty
                      ? 0.0
                      : reviews
                              .map((r) => r.rating)
                              .reduce((a, b) => a + b) /
                          reviews.length;

                  setState(() {
                    _reviews = reviews;
                    _averageRating = avg;
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Review deleted!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Yes',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;

    return AppLayout(
      pageTitle: 'Details',
      showCartFavTbr: true,
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            _TopSection(
              book: book,
              imageFallback: _imageFallback,
            ),

            const SizedBox(height: 18),

            Text(
              'Description',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.description ?? 'No description available.',
              maxLines: _descExpanded ? null : 3,
              overflow: _descExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.darkBrown.withOpacity(0.72),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _descExpanded ? 'View less' : 'View more',
                  style: TextStyle(
                    color: AppColors.darkBrown.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            _StarRatingRow(rating: _averageRating),

            const SizedBox(height: 18),

            _QuantitySelector(
              quantity: _quantity,
              onIncrease: () => setState(() => _quantity++),
              onDecrease: () {
                if (_quantity > 1) setState(() => _quantity--);
              },
            ),

            const SizedBox(height: 18),

            _ReviewsSection(
              reviews: _reviews,
              onAddReview: _showAddReviewDialog,
              onUpdateReview: _showUpdateReviewDialog,
              onDeleteReview: _showDeleteReviewDialog,
            ),

            const SizedBox(height: 18),

            // Red 1: Add to cart + Add to favorites
            Row(
              children: [
                Expanded(
                  child: _PrimaryActionButton(
                    text: 'Add to cart',
                    onTap: () async {
                      try {
                        final cartService = CartService();
                        await cartService.addItem(
                            widget.book.id, _quantity);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to cart!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _isLoadingFav
                      ? _LoadingButton()
                      : _PrimaryActionButton(
                          text: 'Add to favorites',
                          onTap: _addToFavorites,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Red 2: Add to TBR List
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                height: 54,
                child: _isLoadingTBR
                    ? _LoadingButton()
                    : Builder(
                        builder: (buttonContext) => ElevatedButton(
                          onPressed: () => _showTBRMenu(buttonContext),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _isInTBR
                                ? AppColors.mediumBrown
                                : AppColors.darkBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isInTBR
                                ? (_tbrStatus?.label ?? 'In TBR List')
                                : 'Add to TBR List',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'About the author',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.authorBiography ?? 'No biography.',
              maxLines: _authorExpanded ? null : 3,
              overflow: _authorExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.darkBrown.withOpacity(0.72),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () =>
                  setState(() => _authorExpanded = !_authorExpanded),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _authorExpanded ? 'View less' : 'View more',
                  style: TextStyle(
                    color: AppColors.darkBrown.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.pageBg.withOpacity(0.55),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.darkBrown.withOpacity(0.45),
        size: 42,
      ),
    );
  }
}

/* ---------------- TOP SECTION ---------------- */

class _TopSection extends StatelessWidget {
  final Book book;
  final Widget Function() imageFallback;

  const _TopSection({
    required this.book,
    required this.imageFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 128,
            height: 188,
            child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                ? Image.network(
                    book.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => imageFallback(),
                  )
                : imageFallback(),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                book.author,
                style: TextStyle(
                  color: AppColors.darkBrown.withOpacity(0.55),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(book.price ?? 0).toStringAsFixed(2)} BAM',
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (book.categories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: book.categories.take(2).map((cat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBrown,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ---------------- RATING ---------------- */

class _StarRatingRow extends StatelessWidget {
  final double rating;

  const _StarRatingRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            i < rating.floor()
                ? Icons.star
                : (i < rating && rating - i >= 0.5
                    ? Icons.star_half
                    : Icons.star_border),
            color: AppColors.darkBrown,
            size: 31,
          ),
        );
      }),
    );
  }
}

/* ---------------- QUANTITY ---------------- */

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _QuantitySelector({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuantityButton(icon: Icons.add, onTap: onIncrease),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$quantity',
            style: TextStyle(
              color: AppColors.darkBrown,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _QuantityButton(icon: Icons.remove, onTap: onDecrease),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.darkBrown,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

/* ---------------- REVIEWS ---------------- */

class _ReviewsSection extends StatelessWidget {
  final List<BookReview> reviews;
  final VoidCallback onAddReview;
  final Function(BookReview) onUpdateReview;
  final Function(BookReview) onDeleteReview;

  const _ReviewsSection({
    required this.reviews,
    required this.onAddReview,
    required this.onUpdateReview,
    required this.onDeleteReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reviews and ratings!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Text(
              'No reviews yet.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (reviews.length <= 2)
            ...reviews.map(
              (review) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReviewTile(
                  review: review,
                  onUpdate: () => onUpdateReview(review),
                  onDelete: () => onDeleteReview(review),
                ),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReviewTile(
                      review: review,
                      onUpdate: () => onUpdateReview(review),
                      onDelete: () => onDeleteReview(review),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 250,
              height: 44,
              child: ElevatedButton(
                onPressed: onAddReview,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.lightBrown,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add a review',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final BookReview review;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _ReviewTile({
    required this.review,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    review.userFullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (review.comment != null &&
                  review.comment!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  review.comment!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white, size: 18),
          color: AppColors.pageBg,
          onSelected: (value) {
            if (value == 'update') onUpdate();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'update',
              child: Center(
                child: Text(
                  'Update',
                  style: TextStyle(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            PopupMenuItem(
              enabled: false,
              height: 1,
              child: Divider(
                color: AppColors.darkBrown,
                height: 1,
                thickness: 1,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Center(
                child: Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ---------------- BUTTONS ---------------- */

class _PrimaryActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.darkBrown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.darkBrown.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        ),
      ),
    );
  }
}