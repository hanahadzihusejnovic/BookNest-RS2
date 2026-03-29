import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../services/event_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../screens/event_details_screen.dart';
import '../screens/event_reservation_screen.dart';

class EventCategoryScreen extends StatefulWidget {
  final EventCategory category;

  const EventCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<EventCategoryScreen> createState() => _EventCategoryScreenState();
}

class _EventCategoryScreenState extends State<EventCategoryScreen> {
  final _eventService = EventService();

  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  String? _filterEventType; // 'Online', 'InPerson', null = sve
  String? _filterPrice;     // 'free', 'under20', 'over20', null = sve

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final events = await _eventService.getEvents(
        isActive: true,
        pageSize: 50,
      );

      final now = DateTime.now();
      final filtered = events.where((e) {
        return e.eventDate.isAfter(now) &&
            e.eventCategoryId == widget.category.id;
      }).toList();

      if (!mounted) return;
      setState(() {
        _events = filtered;
        _filteredEvents = filtered;
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
      _filteredEvents = _events.where((e) {
        final matchesSearch = q.isEmpty ||
            e.name.toLowerCase().contains(q) ||
            e.organizerName.toLowerCase().contains(q);

        final matchesType =
            _filterEventType == null || e.eventType == _filterEventType;

        final matchesPrice = _filterPrice == null ||
            (_filterPrice == 'free' && e.ticketPrice == 0) ||
            (_filterPrice == 'under20' &&
                e.ticketPrice > 0 &&
                e.ticketPrice < 20) ||
            (_filterPrice == 'over20' && e.ticketPrice >= 20);

        return matchesSearch && matchesType && matchesPrice;
      }).toList();
    });
  }

  void _showFilterDialog() {
    String? tempEventType = _filterEventType;
    String? tempPrice = _filterPrice;

    final typeOptions = [
      {'label': 'All', 'value': null as String?},
      {'label': 'Online', 'value': 'Online'},
      {'label': 'In Person', 'value': 'InPerson'},
    ];

    final priceOptions = [
      {'label': 'All', 'value': null as String?},
      {'label': 'Free', 'value': 'free'},
      {'label': 'Under 20 BAM', 'value': 'under20'},
      {'label': '20 BAM and above', 'value': 'over20'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.pageBg,
              title: Text(
                'Filter events',
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Event type',
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...typeOptions.map((opt) {
                      final isSelected = tempEventType == opt['value'];
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempEventType = opt['value'];
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkBrown
                                : AppColors.mediumBrown.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opt['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    Text(
                      'Price',
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...priceOptions.map((opt) {
                      final isSelected = tempPrice == opt['value'];
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempPrice = opt['value'];
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkBrown
                                : AppColors.mediumBrown.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opt['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterEventType = null;
                      _filterPrice = null;
                    });
                    _applySearch();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(color: AppColors.darkBrown),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterEventType = tempEventType;
                      _filterPrice = tempPrice;
                    });
                    _applySearch();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                  ),
                  child: const Text(
                    'Apply',
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

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: '${widget.category.name} category',
      showCartFavTbr: false,
      showBackButton: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchBar(
                  hint: 'Search by event name or organizer',
                  onChanged: (value) {
                    _query = value;
                    _applySearch();
                  },
                ),
                const SizedBox(height: 10),
                _FilterRow(onTap: _showFilterDialog),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.darkBrown,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            '⚠️ $_error',
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _filteredEvents.isEmpty
                        ? Center(
                            child: Text(
                              'No events found',
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(14, 0, 14, 18),
                            itemCount: _filteredEvents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final event = _filteredEvents[index];
                              return _EventCategoryCard(event: event);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- SEARCH BAR ---------------- */

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
        color: Colors.white.withOpacity(0.35),
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
              color: AppColors.darkBrown.withOpacity(0.55),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- FILTER ROW ---------------- */

class _FilterRow extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            'Filter',
            style: TextStyle(
              color: AppColors.darkBrown,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: AppColors.darkBrown,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/* ---------------- EVENT CATEGORY CARD ---------------- */

class _EventCategoryCard extends StatelessWidget {
  final EventModel event;

  const _EventCategoryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.organizerName} - organizer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _EventInfoLine(
                        label: 'Date & Time',
                        value: event.formattedDate,
                      ),
                      const SizedBox(height: 3),
                      _EventInfoLine(
                        label: 'Theme',
                        value: event.description ?? '-',
                      ),
                      const SizedBox(height: 3),
                      _EventInfoLine(
                        label: 'Location',
                        value: event.location,
                      ),
                    ],
                  ),
                ),
              ),
              _EventImage(imageUrl: event.imageUrl),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _EventActionButton(
                  text: 'Click for\nmore details',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EventDetailsScreen(event: event),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EventActionButton(
                  text: 'Reserve\nspot!',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventReservationScreen(
                            event: event, quantity: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventInfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _EventInfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          height: 1.2,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  final String? imageUrl;

  const _EventImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 78,
        height: 102,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: Colors.white.withOpacity(0.22),
      child: Icon(
        Icons.event,
        color: Colors.white.withOpacity(0.8),
        size: 28,
      ),
    );
  }
}

class _EventActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _EventActionButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.darkBrown,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ),
    );
  }
}