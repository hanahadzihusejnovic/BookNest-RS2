import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../services/event_service.dart';
import '../services/event_category_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import 'event_category_screen.dart';
import '../screens/event_details_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _eventService = EventService();
  final _categoryService = EventCategoryService();

  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  List<EventModel> _basedOnReservations = [];
  List<EventCategory> _categories = [];

  bool _isLoading = true;
  String? _error;
  String _query = '';

  final LayerLink _catLink = LayerLink();
  OverlayEntry? _catOverlay;
  bool _catOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _categoryService.getCategories();
      final events = await _eventService.getEvents(
        isActive: true,
        pageSize: 50,
      );
      final basedOnReservations =
          await _eventService.getContentBasedRecommendations();

      final now = DateTime.now();
      final nextMonth = now.add(const Duration(days: 30));
      final upcoming = events
          .where((e) =>
              e.eventDate.isAfter(now) && e.eventDate.isBefore(nextMonth))
          .toList();

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _allEvents = upcoming;
        _filteredEvents = upcoming;
        _basedOnReservations = basedOnReservations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    final q = _query.trim().toLowerCase();

    setState(() {
      _filteredEvents = _allEvents.where((e) {
        return q.isEmpty ||
            e.name.toLowerCase().contains(q) ||
            e.organizerName.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _toggleCategoriesDropdown() {
    if (_catOpen) {
      _closeCategoriesDropdown();
    } else {
      _showCategoriesDropdown();
    }
  }

  void _closeCategoriesDropdown() {
    _catOverlay?.remove();
    _catOverlay = null;
    if (mounted) {
      setState(() => _catOpen = false);
    }
  }

  void _showCategoriesDropdown() {
    if (_categories.isEmpty) return;

    _catOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeCategoriesDropdown,
                behavior: HitTestBehavior.translucent,
                child: const SizedBox(),
              ),
            ),
            CompositedTransformFollower(
              link: _catLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 180,
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: AppColors.darkBrown,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => Divider(
                      color: AppColors.pageBg,
                      height: 1,
                      thickness: 1,
                      indent: 14,
                      endIndent: 14,
                    ),
                    itemBuilder: (context, i) {
                      final c = _categories[i];
                      return InkWell(
                        onTap: () {
                          _closeCategoriesDropdown();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventCategoryScreen(category: c),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            c.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.pageBg,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
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
          ],
        );
      },
    );

    Overlay.of(context).insert(_catOverlay!);
    setState(() => _catOpen = true);
  }

  @override
  void dispose() {
    _closeCategoriesDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'EVENTS',
      showBackButton: false,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.darkBrown),
                  ),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (_) {
                    if (_catOpen) _closeCategoriesDropdown();
                    return false;
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SearchBar(
                          hint: 'Search by event name or organizer',
                          onChanged: (v) {
                            _query = v;
                            _applySearch();
                          },
                        ),
                        const SizedBox(height: 14),
                        CompositedTransformTarget(
                          link: _catLink,
                          child: InkWell(
                            onTap: _toggleCategoriesDropdown,
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                Text(
                                  'Categories',
                                  style: TextStyle(
                                    color: AppColors.darkBrown,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  _catOpen
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                  color: AppColors.darkBrown,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Available this week
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available this week!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _filteredEvents.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'No events found.',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withValues(alpha: 0.8),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 280,
                                      child: ListView.separated(
                                        itemCount: _filteredEvents.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, i) {
                                          return _EventTile(
                                            event: _filteredEvents[i],
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EventDetailsScreen(
                                                        event:
                                                            _filteredEvents[i]),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Based on your reservations
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Based on your reservations!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _basedOnReservations.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(
                                        'No recommended events right now.',
                                        style: TextStyle(
                                          color:
                                              Colors.white.withValues(alpha: 0.8),
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 280,
                                      child: ListView.separated(
                                        itemCount:
                                            _basedOnReservations.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, i) {
                                          return _EventTile(
                                            event: _basedOnReservations[i],
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EventDetailsScreen(
                                                        event:
                                                            _basedOnReservations[
                                                                i]),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
    );
  }
}

/* ----------------------- WIDGETS ----------------------- */

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: AppColors.darkBrown,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintStyle: TextStyle(
              color: AppColors.darkBrown.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

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
      ),
      child: child,
    );
  }
}

class _EventTile extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.organizerName} - organizer',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date&Time: ${event.formattedDate}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10.8,
                      fontWeight: FontWeight.w500,
                      height: 1.2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 98,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.darkBrown,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
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
                    height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}