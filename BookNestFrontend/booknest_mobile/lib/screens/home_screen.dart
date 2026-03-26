import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/event.dart';
import '../services/book_service.dart';
import '../services/event_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../screens/book_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bookService = BookService();
  final _eventService = EventService();
  List<Book> _topBooks = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _interestedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final books = await _bookService.getRecommendedBooks();
      final events = await _eventService.getEvents(isActive: true, pageSize: 50);
      
      final now = DateTime.now();
      final upcoming = events
          .where((e) => e.eventDate.isAfter(now))
          .take(3)
          .toList();
      
      final interested = events
          .where((e) => e.eventDate.isAfter(now))
          .take(2)
          .toList();

      setState(() {
        _topBooks = books;
        _upcomingEvents = upcoming;
        _interestedEvents = interested;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _topBooks = [];
        _upcomingEvents = [];
        _interestedEvents = [];
        _isLoading = false;
      });
    }
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
      showCartFavTbr: false,
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
                    "Top 5 picks for you!",
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.48,
                    ),
                    itemBuilder: (context, index) {
                      final book = _topBooks[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                        decoration: BoxDecoration(
                          color: AppColors.pageBg.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                                      ? Image.network(
                                          book.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.white.withOpacity(0.45),
                                            child: Icon(
                                              Icons.menu_book_rounded,
                                              color: AppColors.darkBrown.withOpacity(0.5),
                                              size: 28,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.white.withOpacity(0.45),
                                          child: Icon(
                                            Icons.menu_book_rounded,
                                            color: AppColors.darkBrown.withOpacity(0.5),
                                            size: 28,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  Text(
                                    book.title,
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
                                    book.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.darkBrown.withOpacity(0.7),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 22,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookDetailsScreen(book: book),
                                          ),
                                        );
                                      },
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Maybe interested
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
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _interestedEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final e = _interestedEvents[i];
                        return _InterestRow(
                          title: e.name,
                          subtitle: e.description ?? '',
                          timeText: e.formattedDate,
                          onTap: () {},
                        );
                      },
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // Upcoming events
            if (_upcomingEvents.isNotEmpty)
              _SectionCard(
                child: Column(
                  children: [
                    const Text(
                      "Your upcoming events!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mediumBrown.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _upcomingEvents.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _UpcomingEventTile(
                                event: _upcomingEvents[index],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: _SmallButton(
                              text: "See more\nevents",
                              onTap: () {},
                            ),
                          ),
                        ],
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
            color: Colors.black.withOpacity(0.08),
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
        color: AppColors.pageBg.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: _SmallButton(
                text: "Click for more\ndetails", onTap: onTap, height: 38),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  final EventModel event;
  const _UpcomingEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(event.name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text("Date&Time: ${event.formattedDate}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text("Location: ${event.location}",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double height;

  const _SmallButton({
    required this.text,
    required this.onTap,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkBrown.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.pageBg,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}