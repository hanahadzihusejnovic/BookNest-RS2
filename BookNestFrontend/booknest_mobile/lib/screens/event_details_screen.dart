import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/book.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';
import '../screens/event_reservation_screen.dart';
import '../services/reservation_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _reviewService = ReviewService();
  final _authService = AuthService();
  final _reservationService = ReservationService();
  List<BookReview> _reviews = [];
  double _averageRating = 0;
  bool _isLoadingReviews = true;
  int _quantity = 1;
  int? _currentUserId;
  bool _hasMyReview = false;
  bool _descExpanded = false;
  bool _hasReservation = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadCurrentUser();
    _loadReservationStatus();
  }

  Future<void> _loadReservationStatus() async {
    try {
      final reservations = await _reservationService.getMyReservations();
      if (mounted) {
        setState(() {
          _hasReservation = reservations.any(
            (r) => r.eventId == widget.event.id && r.reservationStatus != 'Cancelled',
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _authService.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _hasMyReview = _reviews.any((r) => r.userId == userId);
      });
    }
  }

  void _updateHasMyReview(List<BookReview> reviews) {
    _hasMyReview = reviews.any((r) => r.userId == _currentUserId);
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _reviewService.getEventReviews(widget.event.id);
      final avg = reviews.isEmpty
          ? 0.0
          : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
              reviews.length;
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = avg;
          _isLoadingReviews = false;
          _updateHasMyReview(reviews);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
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
              title: Text('Add a review',
                  style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
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
                  Text('Comment (optional)',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style:
                        TextStyle(color: AppColors.darkBrown, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Write your review...',
                      hintStyle: TextStyle(
                          color: AppColors.darkBrown.withValues(alpha: 0.4),
                          fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
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
                          final nav = Navigator.of(context);
                          final overlay = Overlay.of(context);
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _reviewService.addEventReview(
                              eventId: widget.event.id,
                              rating: selectedRating,
                              comment: commentController.text.isEmpty
                                  ? null
                                  : commentController.text,
                            );
                            final reviews = await _reviewService
                                .getEventReviews(widget.event.id);
                            final avg = reviews.isEmpty
                                ? 0.0
                                : reviews
                                        .map((r) => r.rating)
                                        .reduce((a, b) => a + b) /
                                    reviews.length;
                            if (mounted) {
                              setState(() {
                                _reviews = reviews;
                                _averageRating = avg;
                                _updateHasMyReview(reviews);
                              });
                              nav.pop();
                              AppSnackBar.show(overlay, 'Review added!');
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              AppSnackBar.showError(overlay, e);
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
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Submit',
                          style: TextStyle(color: Colors.white)),
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
              title: Text('Update your review',
                  style: TextStyle(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w800)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
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
                  Text('Comment (optional)',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style:
                        TextStyle(color: AppColors.darkBrown, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Write your review...',
                      hintStyle: TextStyle(
                          color: AppColors.darkBrown.withValues(alpha: 0.4),
                          fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
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
                          final nav = Navigator.of(context);
                          final overlay = Overlay.of(context);
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
                                .getEventReviews(widget.event.id);
                            final avg = reviews.isEmpty
                                ? 0.0
                                : reviews
                                        .map((r) => r.rating)
                                        .reduce((a, b) => a + b) /
                                    reviews.length;
                            if (mounted) {
                              setState(() {
                                _reviews = reviews;
                                _averageRating = avg;
                                _updateHasMyReview(reviews);
                              });
                              nav.pop();
                              AppSnackBar.show(overlay, 'Review updated!');
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              AppSnackBar.showError(overlay, e);
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
                              color: Colors.white, strokeWidth: 2))
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
          title: Text('Delete review',
              style: TextStyle(
                  color: AppColors.darkBrown, fontWeight: FontWeight.w800)),
          content: Text(
            'Are you sure you want to delete your review?',
            style: TextStyle(
                color: AppColors.darkBrown.withValues(alpha: 0.8), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('No', style: TextStyle(color: AppColors.darkBrown)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final overlay = Overlay.of(context);
                try {
                  await _reviewService.deleteReview(review.id);
                  final reviews =
                      await _reviewService.getEventReviews(widget.event.id);
                  final avg = reviews.isEmpty
                      ? 0.0
                      : reviews
                              .map((r) => r.rating)
                              .reduce((a, b) => a + b) /
                          reviews.length;
                  if (mounted) {
                    setState(() {
                      _reviews = reviews;
                      _averageRating = avg;
                      _updateHasMyReview(reviews);
                    });
                    nav.pop();
                    AppSnackBar.show(overlay, 'Review deleted!');
                  }
                } catch (e) {
                  if (mounted) {
                    nav.pop();
                    AppSnackBar.showError(overlay, e);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return AppLayout(
      pageTitle: 'Event Details',
      showBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 165,
                  height: 210,
                  child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? Image.network(
                          event.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Text(
                event.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 18),

            _PlainInfoLine(label: 'Organizer', value: event.organizerName),
            const SizedBox(height: 8),
            _PlainInfoLine(label: 'Date & Time', value: event.formattedDate),
            const SizedBox(height: 8),
            _PlainInfoLine(label: 'Location', value: event.location),
            const SizedBox(height: 8),
            _PlainInfoLine(
                label: 'Participants',
                value: '${event.reservedSeats}/${event.capacity}'),
            const SizedBox(height: 8),
            _PlainInfoLine(
              label: 'Price',
              value: event.ticketPrice == 0
                  ? 'Free'
                  : '${event.ticketPrice.toStringAsFixed(0)} BAM',
            ),
            const SizedBox(height: 8),
            Text(
              'Description:',
              style: TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 14,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              event.description ?? 'No description available.',
              maxLines: _descExpanded ? null : 3,
              overflow: _descExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.darkBrown.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _descExpanded ? 'View less' : 'View more',
                  style: TextStyle(
                    color: AppColors.darkBrown.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Star rating
            Row(
              children: List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    i < _averageRating.floor()
                        ? Icons.star
                        : (i < _averageRating && _averageRating - i >= 0.5
                            ? Icons.star_half
                            : Icons.star_border),
                    color: AppColors.darkBrown,
                    size: 31,
                  ),
                );
              }),
            ),

            const SizedBox(height: 18),

            // Quantity selector
            Row(
              children: [
                _QuantityButton(
                  icon: Icons.add,
                  onTap: () {
                    final available = event.capacity - event.reservedSeats;
                    if (_quantity < available) {
                      setState(() => _quantity++);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    '$_quantity',
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _QuantityButton(
                  icon: Icons.remove,
                  onTap: () {
                    if (_quantity > 1) setState(() => _quantity--);
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Reviews
            _isLoadingReviews
                ? Center(
                    child: CircularProgressIndicator(
                        color: AppColors.darkBrown))
                : _ReviewsSection(
                    reviews: _reviews,
                    hasMyReview: _hasMyReview,
                    eventPassed: widget.event.eventDate.isBefore(DateTime.now()),
                    onAddReview: _showAddReviewDialog,
                    onUpdateReview: _showUpdateReviewDialog,
                    onDeleteReview: _showDeleteReviewDialog,
                  ),

            const SizedBox(height: 18),

            Center(
              child: SizedBox(
                width: 180,
                height: 42,
                child: ElevatedButton(
                  onPressed: _hasReservation
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventReservationScreen(
                                event: widget.event,
                                quantity: _quantity,
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.darkBrown,
                    disabledBackgroundColor: AppColors.mediumBrown,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    _hasReservation ? 'ALREADY RESERVED' : 'RESERVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: _hasReservation ? 11 : 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6),
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
      color: AppColors.mediumBrown.withValues(alpha: 0.35),
      child: Icon(Icons.event,
          color: AppColors.darkBrown.withValues(alpha: 0.45), size: 56),
    );
  }
}

/* ----------------------- PLAIN INFO LINE ----------------------- */

class _PlainInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _PlainInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
            color: AppColors.darkBrown.withValues(alpha: 0.82),
            fontSize: 13,
            height: 1.3),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
                color: AppColors.darkBrown, fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
                color: AppColors.darkBrown.withValues(alpha: 0.78),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/* ----------------------- QUANTITY BUTTON ----------------------- */

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

/* ----------------------- REVIEWS SECTION ----------------------- */

class _ReviewsSection extends StatelessWidget {
  final List<BookReview> reviews;
  final bool hasMyReview;
  final bool eventPassed;
  final VoidCallback onAddReview;
  final Function(BookReview) onUpdateReview;
  final Function(BookReview) onDeleteReview;

  const _ReviewsSection({
    required this.reviews,
    required this.hasMyReview,
    required this.eventPassed,
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
          const Text('Reviews and ratings!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Text('No reviews yet.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500))
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
                onPressed: (hasMyReview || !eventPassed) ? null : onAddReview,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.darkBrown,
                  disabledBackgroundColor: AppColors.lightBrown,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                    hasMyReview
                        ? 'Already reviewed'
                        : !eventPassed
                            ? 'Event not held yet'
                            : 'Add a review',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700)),
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

  const _ReviewTile(
      {required this.review, required this.onUpdate, required this.onDelete});

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
                      review.userFullName.isNotEmpty
                          ? review.userFullName
                          : 'Anonymous',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
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
                Text(review.comment!,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                        height: 1.3)),
              ],
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 18),
          color: AppColors.pageBg,
          onSelected: (value) {
            if (value == 'update') onUpdate();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'update',
              child: Center(
                  child: Text('Update',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w600))),
            ),
            PopupMenuItem(
              enabled: false,
              height: 1,
              child: Divider(
                  color: AppColors.darkBrown, height: 1, thickness: 1),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Center(
                  child: Text('Delete',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600))),
            ),
          ],
        ),
      ],
    );
  }
}