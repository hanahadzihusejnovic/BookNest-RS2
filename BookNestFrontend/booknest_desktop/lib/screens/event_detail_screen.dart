import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../models/organizer.dart';
import '../models/reservation.dart';
import '../services/city_service.dart';
import '../services/country_service.dart';
import '../services/event_service.dart';
import '../services/event_category_service.dart';
import '../services/organizer_service.dart';
import '../services/reservation_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import 'events_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  final _reservationService = ReservationService();

  Event? _event;
  List<Reservation> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final event = await _eventService.getEvent(widget.eventId);
      final reservations = await _eventService
          .getEventReservations(widget.eventId)
          .catchError((_) => <Reservation>[]);
      if (!mounted) return;
      setState(() {
        _event = event;
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load event', isError: true);
      }
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}.${d.month}.${d.year}';
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    return '${parts[0]}:${parts[1]}';
  }

  static const _reservationTransitions = {
    'Pending':   [('Confirmed', 1), ('Cancelled', 2)],
    'Confirmed': [('Attended', 3),  ('Cancelled', 2)],
  };

  Future<void> _changeReservationStatus(Reservation r) async {
    final options = _reservationTransitions[r.reservationStatus];
    if (options == null || options.isEmpty) return;
    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Change Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((o) => ListTile(
                    title: Text(o.$1, style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(ctx, o.$2),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    try {
      await _reservationService.updateStatus(r.id, chosen);
      if (mounted) {
        AppSnackBar.show(context, 'Status updated');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update status', isError: true);
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Event',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${_event!.name}"?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFE57373)))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _eventService.deleteEvent(widget.eventId);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
        AppSnackBar.show(context, 'Event deleted successfully');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete event', isError: true);
    }
  }

  void _openEditDialog() {
    if (_event == null) return;
    showDialog(
      context: context,
      builder: (_) => _EditEventDialog(event: _event!, onUpdated: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'EVENTS',
      onBack: () => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const EventsScreen())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
          : _event == null
              ? const Center(
                  child: Text('Event not found.',
                      style: TextStyle(color: AppColors.mediumBrown)))
              : _buildContent(_event!),
    );
  }

  Widget _buildContent(Event event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(event),
          const SizedBox(height: 32),
          _buildReservations(),
        ],
      ),
    );
  }

  Widget _buildHeader(Event event) {
    final isOnline = event.eventType.toLowerCase() == 'online';
    final available = event.capacity - event.reservedSeats;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 220,
            height: 300,
            child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                ? Image.network(event.imageUrl!, fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
        ),
        const SizedBox(width: 32),

        // Details — two columns
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.name,
                style: const TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _Badge(event.eventType == 'InPerson' ? 'In Person' : event.eventType),
                  const SizedBox(width: 8),
                  _Badge(event.isActive ? 'Active' : 'Inactive',
                      color: event.isActive
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE57373)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DetailRow('Category:', event.eventCategoryName),
                        const SizedBox(height: 10),
                        DetailRow('Organizer:', event.organizerName),
                        const SizedBox(height: 10),
                        DetailRow('Date:', _fmtDate(event.eventDate)),
                        const SizedBox(height: 10),
                        DetailRow('Time:', _fmtTime(event.eventTime)),
                        const SizedBox(height: 10),
                        DetailRow('Ticket Price:',
                            event.ticketPrice == 0 ? 'Free' : '${event.ticketPrice.toStringAsFixed(2)} BAM'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isOnline)
                          DetailRow('Location:', 'Online event')
                        else ...[
                          DetailRow('Address:', event.address ?? '-'),
                          const SizedBox(height: 10),
                          DetailRow('City:', event.city ?? '-'),
                          const SizedBox(height: 10),
                          DetailRow('Country:', event.country ?? '-'),
                        ],
                        const SizedBox(height: 10),
                        DetailRow('Capacity:', '${event.capacity} seats'),
                        const SizedBox(height: 10),
                        DetailRow('Reserved:', '${event.reservedSeats} seats'),
                        const SizedBox(height: 10),
                        DetailRow('Available:', '$available seats'),
                      ],
                    ),
                  ),
                ],
              ),
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Description',
                    style: const TextStyle(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(event.description!,
                    style: const TextStyle(
                        color: AppColors.darkBrown, fontSize: 15)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 28),

        // Action buttons
        Column(
          children: [
            DetailActionButton(icon: Icons.edit_outlined, label: 'EDIT EVENT', onTap: _openEditDialog),
            const SizedBox(height: 12),
            DetailActionButton(icon: Icons.delete_outline, label: 'DELETE EVENT', onTap: _deleteEvent),
          ],
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.lightBrown.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(Icons.event_outlined, color: AppColors.mediumBrown, size: 64),
        ),
      );

  Widget _buildReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reservations',
            style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('User', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 3, child: Text('Email', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Date', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 1, child: Text('Qty', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Total', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              SizedBox(width: 140),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        if (_reservations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No reservations yet.',
                style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reservations.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.darkBrown.withValues(alpha: 0.15), thickness: 1, height: 1),
            itemBuilder: (ctx, i) {
              final r = _reservations[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(r.userFullName, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 3, child: Text(r.userEmail, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(_fmtDate(r.reservationDate), style: adminRowStyle)),
                    Expanded(flex: 1, child: Text('${r.quantity}', style: adminRowStyle)),
                    Expanded(flex: 2, child: Text(r.totalPrice == 0 ? 'Free' : '${r.totalPrice.toStringAsFixed(2)} BAM', style: adminRowStyle)),
                    Expanded(flex: 2, child: Text(r.reservationStatus, style: adminRowStyle)),
                    if (_reservationTransitions.containsKey(r.reservationStatus))
                      SizedBox(
                        width: 140,
                        height: 34,
                        child: ElevatedButton.icon(
                          onPressed: () => _changeReservationStatus(r),
                          icon: const Icon(Icons.swap_horiz, size: 15),
                          label: const Text('CHANGE STATUS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.darkBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 140),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;

  const _Badge(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.mediumBrown).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? AppColors.mediumBrown).withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.darkBrown,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Edit Dialog ─────────────────────────────────────────────────────────────

class _EditEventDialog extends StatefulWidget {
  final Event event;
  final VoidCallback onUpdated;

  const _EditEventDialog({required this.event, required this.onUpdated});

  @override
  State<_EditEventDialog> createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<_EditEventDialog> {
  final _eventService = EventService();
  final _categoryService = EventCategoryService();
  final _organizerService = OrganizerService();
  final _cityService = CityService();
  final _countryService = CountryService();

  static const _eventTypeLabels = ['Online', 'In Person'];

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _capacityController;
  late final TextEditingController _addressController;

  List<EventCategory> _categories = [];
  List<Organizer> _organizers = [];
  List<City> _cities = [];
  List<City> _filteredCities = [];
  List<Country> _countries = [];
  bool _dataLoading = true;

  EventCategory? _selectedCategory;
  Organizer? _selectedOrganizer;
  int? _selectedEventType;
  City? _selectedCity;
  Country? _selectedCountry;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isActive = true;
  File? _newImage;
  bool _imageDeleted = false;
  bool _isLoading = false;

  String? _nameError;
  String? _categoryError;
  String? _organizerError;
  String? _eventTypeError;
  String? _dateError;
  String? _timeError;
  String? _priceError;
  String? _capacityError;

  final LayerLink _categoryLink = LayerLink();
  OverlayEntry? _categoryOverlay;
  bool _categoryOpen = false;

  final LayerLink _organizerLink = LayerLink();
  OverlayEntry? _organizerOverlay;
  bool _organizerOpen = false;

  final LayerLink _eventTypeLink = LayerLink();
  OverlayEntry? _eventTypeOverlay;
  bool _eventTypeOpen = false;

  final LayerLink _countryLink = LayerLink();
  OverlayEntry? _countryOverlay;
  bool _countryOpen = false;

  final LayerLink _cityLink = LayerLink();
  OverlayEntry? _cityOverlay;
  bool _cityOpen = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _nameController = TextEditingController(text: e.name);
    _descriptionController = TextEditingController(text: e.description ?? '');
    _priceController = TextEditingController(text: e.ticketPrice.toStringAsFixed(2));
    _capacityController = TextEditingController(text: '${e.capacity}');
    _addressController = TextEditingController(text: e.address ?? '');
    _selectedDate = e.eventDate;
    _isActive = e.isActive;
    _selectedEventType = e.eventType.toLowerCase() == 'online' ? 0 : 1;
    final parts = e.eventTime.split(':');
    if (parts.length >= 2) {
      _selectedTime = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _categoryService.getCategories(),
        _organizerService.getOrganizers(),
        _cityService.getCities(),
        _countryService.getCountries(),
      ]);
      if (!mounted) return;
      final cats = results[0] as List<EventCategory>;
      final orgs = results[1] as List<Organizer>;
      final cities = results[2] as List<City>;
      final countries = results[3] as List<Country>;
      setState(() {
        _categories = cats;
        _organizers = orgs;
        _cities = cities;
        _countries = countries;
        _selectedCategory = cats.firstWhere(
          (c) => c.id == widget.event.eventCategoryId,
          orElse: () => cats.first,
        );
        _selectedOrganizer = orgs.firstWhere(
          (o) => o.name == widget.event.organizerName,
          orElse: () => orgs.first,
        );
        if (widget.event.countryId != null) {
          try {
            _selectedCountry = countries.firstWhere((c) => c.id == widget.event.countryId);
            _filteredCities = cities.where((c) => c.countryId == _selectedCountry!.id).toList();
          } catch (_) {}
        }
        if (widget.event.cityId != null && _filteredCities.isNotEmpty) {
          try {
            _selectedCity = _filteredCities.firstWhere((c) => c.id == widget.event.cityId);
          } catch (_) {}
        }
        _dataLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _dataLoading = false);
    }
  }

  void _closeAll() {
    _closeCategoryDropdown();
    _closeOrganizerDropdown();
    _closeEventTypeDropdown();
    _closeCountryDropdown();
    _closeCityDropdown();
  }

  void _closeCountryDropdown() {
    _countryOverlay?.remove(); _countryOverlay = null;
    if (mounted) setState(() => _countryOpen = false);
  }

  void _closeCityDropdown() {
    _cityOverlay?.remove(); _cityOverlay = null;
    if (mounted) setState(() => _cityOpen = false);
  }

  void _onCountryChanged(Country country) {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _filteredCities = _cities.where((c) => c.countryId == country.id).toList();
    });
  }

  void _toggleCountryDropdown() {
    if (_countryOpen) { _closeCountryDropdown(); return; }
    _closeAll();
    _countryOverlay = _showOverlay<Country>(
      link: _countryLink, items: _countries, selected: _selectedCountry,
      labelFn: (c) => c.name,
      onSelect: _onCountryChanged,
      onClose: _closeCountryDropdown,
    );
    setState(() => _countryOpen = true);
  }

  void _toggleCityDropdown() {
    if (_selectedCountry == null) return;
    if (_cityOpen) { _closeCityDropdown(); return; }
    _closeAll();
    _cityOverlay = _showOverlay<City>(
      link: _cityLink, items: _filteredCities, selected: _selectedCity,
      labelFn: (c) => c.name,
      onSelect: (c) => setState(() => _selectedCity = c),
      onClose: _closeCityDropdown,
    );
    setState(() => _cityOpen = true);
  }

  void _closeCategoryDropdown() {
    _categoryOverlay?.remove(); _categoryOverlay = null;
    if (mounted) setState(() => _categoryOpen = false);
  }

  void _closeOrganizerDropdown() {
    _organizerOverlay?.remove(); _organizerOverlay = null;
    if (mounted) setState(() => _organizerOpen = false);
  }

  void _closeEventTypeDropdown() {
    _eventTypeOverlay?.remove(); _eventTypeOverlay = null;
    if (mounted) setState(() => _eventTypeOpen = false);
  }

  OverlayEntry _showOverlay<T>({
    required LayerLink link,
    required List<T> items,
    required T? selected,
    required String Function(T) labelFn,
    required void Function(T) onSelect,
    required void Function() onClose,
  }) {
    final entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: onClose, behavior: HitTestBehavior.translucent, child: const SizedBox())),
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: const Offset(0, 44),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(color: AppColors.lightBrown, borderRadius: BorderRadius.circular(6)),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(color: AppColors.darkBrown.withValues(alpha: 0.2), height: 1, thickness: 1, indent: 14, endIndent: 14),
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    return InkWell(
                      onTap: () { onClose(); onSelect(item); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(labelFn(item).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.darkBrown, fontSize: 11.5, letterSpacing: 0.6,
                              fontWeight: item == selected ? FontWeight.w900 : FontWeight.w500,
                            )),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  void _toggleCategory() {
    if (_categoryOpen) { _closeCategoryDropdown(); return; }
    _closeAll();
    _categoryOverlay = _showOverlay<EventCategory>(
      link: _categoryLink, items: _categories, selected: _selectedCategory,
      labelFn: (c) => c.name,
      onSelect: (c) => setState(() { _selectedCategory = c; _categoryError = null; }),
      onClose: _closeCategoryDropdown,
    );
    setState(() => _categoryOpen = true);
  }

  void _toggleOrganizer() {
    if (_organizerOpen) { _closeOrganizerDropdown(); return; }
    _closeAll();
    _organizerOverlay = _showOverlay<Organizer>(
      link: _organizerLink, items: _organizers, selected: _selectedOrganizer,
      labelFn: (o) => o.name,
      onSelect: (o) => setState(() { _selectedOrganizer = o; _organizerError = null; }),
      onClose: _closeOrganizerDropdown,
    );
    setState(() => _organizerOpen = true);
  }

  void _toggleEventType() {
    if (_eventTypeOpen) { _closeEventTypeDropdown(); return; }
    _closeAll();
    _eventTypeOverlay = _showOverlay<int>(
      link: _eventTypeLink, items: [0, 1], selected: _selectedEventType,
      labelFn: (i) => _eventTypeLabels[i],
      onSelect: (i) => setState(() { _selectedEventType = i; _eventTypeError = null; }),
      onClose: _closeEventTypeDropdown,
    );
    setState(() => _eventTypeOpen = true);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020), lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lightBrown, onPrimary: AppColors.darkBrown,
            surface: AppColors.darkBrown, onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _selectedDate = picked; _dateError = null; });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lightBrown, onPrimary: AppColors.darkBrown,
            surface: AppColors.darkBrown, onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _selectedTime = picked; _timeError = null; });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() { _newImage = File(result.files.single.path!); _imageDeleted = false; });
    }
  }

  Future<void> _removeImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Remove Image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Remove the event image?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Color(0xFFE57373)))),
        ],
      ),
    );
    if (confirmed == true) setState(() { _newImage = null; _imageDeleted = true; });
  }

  Future<void> _submit() async {
    final isInPerson = _selectedEventType == 1;
    setState(() {
      _nameError = _nameController.text.isEmpty ? 'Required' : null;
      _categoryError = _selectedCategory == null ? 'Required' : null;
      _organizerError = _selectedOrganizer == null ? 'Required' : null;
      _eventTypeError = _selectedEventType == null ? 'Required' : null;
      _dateError = _selectedDate == null ? 'Required' : null;
      _timeError = _selectedTime == null ? 'Required' : null;
      _priceError = _priceController.text.isEmpty ? 'Required' : null;
      _capacityError = _capacityController.text.isEmpty ? 'Required' : null;
    });
    if ([_nameError, _categoryError, _organizerError, _eventTypeError,
         _dateError, _timeError, _priceError, _capacityError].any((e) => e != null)) {
      return;
    }

    final price = double.tryParse(_priceController.text);
    final capacity = int.tryParse(_capacityController.text);
    if (price == null) { setState(() => _priceError = 'Invalid number'); return; }
    if (capacity == null) { setState(() => _capacityError = 'Invalid number'); return; }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_newImage != null) {
        try {
          imageUrl = await _eventService.uploadImage(_newImage!, category: _selectedCategory?.name);
        } catch (_) { imageUrl = widget.event.imageUrl; }
      } else if (_imageDeleted) {
        imageUrl = null;
      } else {
        imageUrl = widget.event.imageUrl;
      }
      final h = _selectedTime!.hour.toString().padLeft(2, '0');
      final m = _selectedTime!.minute.toString().padLeft(2, '0');
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'eventCategoryId': _selectedCategory!.id,
        'organizerId': _selectedOrganizer!.id,
        'eventDate': _selectedDate!.toIso8601String(),
        'eventTime': '$h:$m:00',
        'eventType': _selectedEventType!,
        'ticketPrice': price,
        'capacity': capacity,
        'isActive': _isActive,
        'reservedSeats': widget.event.reservedSeats,
        if (_descriptionController.text.isNotEmpty) 'description': _descriptionController.text.trim(),
        if (isInPerson && _addressController.text.isNotEmpty) 'address': _addressController.text.trim(),
        if (isInPerson && _selectedCountry != null) 'countryId': _selectedCountry!.id,
        if (isInPerson && _selectedCity != null) 'cityId': _selectedCity!.id,
        'imageUrl': imageUrl,
      };
      await _eventService.updateEvent(widget.event.id, body);
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        AppSnackBar.show(context, 'Event updated successfully');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update event', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 680,
        child: _dataLoading
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.lightBrown)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('EDIT EVENT',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column
                        Expanded(
                          child: Column(
                            children: [
                              BookFormField(controller: _nameController, hint: 'Name', error: _nameError, onChanged: (_) => setState(() => _nameError = null)),
                              const SizedBox(height: 14),
                              BookFormDropdownTrigger(link: _categoryLink, hint: 'Category', selectedLabel: _selectedCategory?.name, isOpen: _categoryOpen, error: _categoryError, onTap: _toggleCategory),
                              const SizedBox(height: 14),
                              BookFormDropdownTrigger(link: _organizerLink, hint: 'Organizer', selectedLabel: _selectedOrganizer?.name, isOpen: _organizerOpen, error: _organizerError, onTap: _toggleOrganizer),
                              const SizedBox(height: 14),
                              BookFormDropdownTrigger(link: _eventTypeLink, hint: 'Event Type', selectedLabel: _selectedEventType != null ? _eventTypeLabels[_selectedEventType!] : null, isOpen: _eventTypeOpen, error: _eventTypeError, onTap: _toggleEventType),
                              const SizedBox(height: 14),
                              // Image picker
                              Builder(builder: (_) {
                                final hasAny = _newImage != null || (!_imageDeleted && widget.event.imageUrl != null);
                                return Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: double.infinity, height: 110,
                                        decoration: BoxDecoration(
                                          color: AppColors.lightBrown.withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.4)),
                                        ),
                                        child: _newImage != null
                                            ? ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.file(_newImage!, fit: BoxFit.cover))
                                            : (!_imageDeleted && widget.event.imageUrl != null)
                                                ? ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.network(widget.event.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.event_outlined, color: AppColors.lightBrown, size: 32)))
                                                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                                    const Icon(Icons.image_outlined, color: AppColors.lightBrown, size: 32),
                                                    const SizedBox(height: 6),
                                                    Text('Import picture', style: TextStyle(color: AppColors.lightBrown.withValues(alpha: 0.8), fontSize: 13)),
                                                  ]),
                                      ),
                                    ),
                                    if (hasAny) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: _pickImage,
                                            child: Text('Change cover', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600)),
                                          ),
                                          Text('  |  ', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                                          GestureDetector(
                                            onTap: _removeImage,
                                            child: Text('Remove', style: TextStyle(color: Colors.red.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              }),
                              const SizedBox(height: 14),
                              BookFormField(controller: _descriptionController, hint: 'Description (optional)', maxLines: 3, onChanged: (_) {}),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right column
                        Expanded(
                          child: Column(
                            children: [
                              _DateTrigger(
                                label: _selectedDate != null ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}' : 'Event Date',
                                hasValue: _selectedDate != null, error: _dateError,
                                icon: Icons.calendar_today_outlined, onTap: _pickDate,
                              ),
                              const SizedBox(height: 14),
                              _DateTrigger(
                                label: _selectedTime != null ? _selectedTime!.format(context) : 'Event Time',
                                hasValue: _selectedTime != null, error: _timeError,
                                icon: Icons.access_time_outlined, onTap: _pickTime,
                              ),
                              const SizedBox(height: 14),
                              BookFormField(controller: _priceController, hint: 'Ticket Price', error: _priceError, keyboardType: TextInputType.number, onChanged: (_) => setState(() => _priceError = null)),
                              const SizedBox(height: 14),
                              BookFormField(controller: _capacityController, hint: 'Capacity', error: _capacityError, keyboardType: TextInputType.number, onChanged: (_) => setState(() => _capacityError = null)),
                              const SizedBox(height: 14),
                              BookFormField(controller: _addressController, hint: _selectedEventType == 1 ? 'Address' : 'Address (optional)', onChanged: (_) {}),
                              const SizedBox(height: 14),
                              BookFormDropdownTrigger(link: _countryLink, hint: _selectedEventType == 1 ? 'Country' : 'Country (optional)', selectedLabel: _selectedCountry?.name, isOpen: _countryOpen, onTap: _toggleCountryDropdown),
                              const SizedBox(height: 14),
                              BookFormDropdownTrigger(link: _cityLink, hint: _selectedCountry == null ? 'Select country first' : (_selectedEventType == 1 ? 'City' : 'City (optional)'), selectedLabel: _selectedCity?.name, isOpen: _cityOpen, onTap: _toggleCityDropdown),
                              const SizedBox(height: 14),
                              Row(children: [
                                Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeThumbColor: AppColors.lightBrown),
                                const SizedBox(width: 8),
                                const Text('Active', style: TextStyle(color: Colors.white, fontSize: 14)),
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.lightBrown),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.lightBrown,
                              disabledBackgroundColor: AppColors.lightBrown.withValues(alpha: 0.7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.darkBrown, strokeWidth: 2))
                                : const Text('Save', style: TextStyle(color: AppColors.darkBrown, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _categoryOverlay?.remove();
    _organizerOverlay?.remove();
    _eventTypeOverlay?.remove();
    _countryOverlay?.remove();
    _cityOverlay?.remove();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class _DateTrigger extends StatelessWidget {
  final String label;
  final bool hasValue;
  final String? error;
  final IconData icon;
  final VoidCallback onTap;

  const _DateTrigger({required this.label, required this.hasValue, this.error, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.lightBrown.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: error != null ? Colors.red.withValues(alpha: 0.7) : AppColors.lightBrown.withValues(alpha: 0.4)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.lightBrown),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: hasValue ? Colors.white : AppColors.lightBrown.withValues(alpha: 0.7), fontSize: 14)),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
