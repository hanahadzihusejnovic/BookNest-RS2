import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/event.dart';
import '../services/book_service.dart';
import '../services/event_service.dart';
import '../services/reservation_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../widgets/book_card.dart';
import '../screens/book_details_screen.dart';
import '../screens/event_details_screen.dart';
import '../screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bookService = BookService();
  final _eventService = EventService();
  final _reservationService = ReservationService();

  List<Book> _topBooks = [];
  List<EventModel> _interestedEvents = [];
  List<ReservationModel> _upcomingReservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final books = await _bookService.getRecommendedBooks();
      final recommended = await _eventService.getRecommendedEvents();
      final reservations = await _reservationService.getMyReservations();

      final now = DateTime.now();
      final upcoming = reservations
          .where((r) => r.eventDateTime.isAfter(now))
          .take(3)
          .toList();

      if (!mounted) return;
      setState(() {
        _topBooks = books;
        _interestedEvents = recommended;
        _upcomingReservations = upcoming;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _topBooks = [];
        _interestedEvents = [];
        _upcomingReservations = [];
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[date.weekday - 1]} at '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.pageBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.darkBrown),
        ),
      );
    }

    return AppLayout(
      pageTitle: 'HOME',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top picks
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Top picks for you!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _topBooks.take(6).length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.48,
                    ),
                    itemBuilder: (context, index) {
                      final book = _topBooks[index];
                      return BookCard(
                        title: book.title,
                        author: book.author,
                        imageUrl: book.imageUrl,
                        style: BookCardStyle.details,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookDetailsScreen(book: book),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Maybe interested — collaborative filtering
            if (_interestedEvents.isNotEmpty)
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Maybe you are interested in...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _interestedEvents.length <= 3
                        ? ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _interestedEvents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final e = _interestedEvents[i];
                              return _InterestRow(
                                title: e.name,
                                subtitle: e.description ?? '',
                                timeText: e.formattedDate,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EventDetailsScreen(event: e),
                                  ),
                                ),
                              );
                            },
                          )
                        : SizedBox(
                            height: 280,
                            child: ListView.separated(
                              itemCount: _interestedEvents.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final e = _interestedEvents[i];
                                return _InterestRow(
                                  title: e.name,
                                  subtitle: e.description ?? '',
                                  timeText: e.formattedDate,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EventDetailsScreen(event: e),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // Upcoming events — korisnikove rezervacije
            if (_upcomingReservations.isNotEmpty)
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your upcoming events!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _upcomingReservations.length <= 3
                        ? ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _upcomingReservations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final r = _upcomingReservations[index];
                              return _UpcomingReservationRow(
                                eventName: r.eventName,
                                dateText: _formatDate(r.eventDateTime),
                                location: r.eventLocation,
                              );
                            },
                          )
                        : SizedBox(
                            height: 280,
                            child: ListView.separated(
                              itemCount: _upcomingReservations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final r = _upcomingReservations[index];
                                return _UpcomingReservationRow(
                                  eventName: r.eventName,
                                  dateText: _formatDate(r.eventDateTime),
                                  location: r.eventLocation,
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 160,
                        height: 32,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.darkBrown,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'See more events',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 22),
          ],
        ),
      ),
    );
  }
}

/* ----------------------- WIDGETS ----------------------- */

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InterestRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeText;
  final VoidCallback onTap;

  const _InterestRow({
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text("Date&Time: $timeText",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                        height: 1.2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.darkBrown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              ),
              child: const Text(
                'Click for more\ndetails',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingReservationRow extends StatelessWidget {
  final String eventName;
  final String dateText;
  final String location;

  const _UpcomingReservationRow({
    required this.eventName,
    required this.dateText,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eventName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Date&Time: $dateText',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Location: $location',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w500,
                  height: 1.2)),
        ],
      ),
    );
  }
}