import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/event.dart';
import '../models/event_category.dart';
import '../models/organizer.dart';
import '../services/event_service.dart';
import '../services/event_category_service.dart';
import '../services/organizer_service.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _eventService = EventService();
  final _categoryService = EventCategoryService();
  final _searchController = TextEditingController();

  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  List<EventCategory> _categories = [];
  EventCategory? _selectedCategory;
  bool _isLoading = true;

  final LayerLink _catLink = LayerLink();
  OverlayEntry? _catOverlay;
  bool _catOpen = false;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<Event> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredEvents.length);
    return _filteredEvents.sublist(start, end);
  }

  int get _totalPages => (_filteredEvents.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _eventService.getEvents(),
        _categoryService.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _allEvents = results[0] as List<Event>;
        _categories = results[1] as List<EventCategory>;
        _filteredEvents = _allEvents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(context, 'Failed to load events', isError: true);
    }
  }

  void _onSearchChanged(String query) => _applyFilters(query: query);

  void _onCategoryChanged(EventCategory? category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
    });
    _applyFilters(query: _searchController.text);
  }

  void _applyFilters({String? query}) {
    final q = (query ?? _searchController.text).trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filteredEvents = _allEvents.where((e) {
        final matchesSearch = q.isEmpty ||
            e.name.toLowerCase().contains(q) ||
            e.organizerName.toLowerCase().contains(q);
        final matchesCategory = _selectedCategory == null ||
            e.eventCategoryId == _selectedCategory!.id;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _openAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddEventDialog(
        categories: _categories,
        onCreated: _loadData,
      ),
    );
  }

  String _formatDateTime(Event event) {
    final d = event.eventDate;
    final dateStr = '${d.day}.${d.month}.${d.year}';
    final parts = event.eventTime.split(':');
    if (parts.length < 2) return dateStr;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour < 12 ? 'am' : 'pm';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr =
        minute == 0 ? '$h$period' : '$h.${minute.toString().padLeft(2, '0')}$period';
    return '$dateStr - $timeStr';
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
    if (mounted) setState(() => _catOpen = false);
  }

  void _showCategoriesDropdown() {
    if (_categories.isEmpty) return;
    final allItems = <EventCategory?>[null, ..._categories];

    _catOverlay = OverlayEntry(
      builder: (context) => Stack(
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
            offset: const Offset(-6, 28),
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
                  shrinkWrap: true,
                  itemCount: allItems.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.pageBg,
                    height: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
                  ),
                  itemBuilder: (context, i) {
                    final cat = allItems[i];
                    final selected = cat == null
                        ? _selectedCategory == null
                        : _selectedCategory?.id == cat.id;
                    return InkWell(
                      onTap: () {
                        _closeCategoriesDropdown();
                        _onCategoryChanged(cat);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(
                          (cat?.name ?? 'ALL').toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.pageBg,
                            fontSize: 11.5,
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w500,
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
      ),
    );

    Overlay.of(context).insert(_catOverlay!);
    setState(() => _catOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'EVENTS',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: category dropdown + add button
            Row(
              children: [
                CompositedTransformTarget(
                  link: _catLink,
                  child: InkWell(
                    onTap: _toggleCategoriesDropdown,
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        const Text(
                          'Categories: ',
                          style: TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _selectedCategory?.name ?? 'All',
                          style: const TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                const Spacer(),
                ElevatedButton(
                  onPressed: _openAddEventDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    'Add New Event',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search bar
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style:
                    const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search by name, organizer',
                  hintStyle:
                      TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  SizedBox(width: 56),
                  AdminColHeader('Name', flex: 3),
                  AdminColHeader('Category', flex: 2),
                  AdminColHeader('Organizator', flex: 2),
                  AdminColHeader('Date & Time', flex: 3),
                  SizedBox(width: 120),
                ],
              ),
            ),
            Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.25),
                thickness: 1,
                height: 12),

            // Events list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.darkBrown))
                  : _filteredEvents.isEmpty
                      ? const Center(
                          child: Text('No events found.',
                              style: TextStyle(
                                  color: AppColors.mediumBrown, fontSize: 14)))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: _currentPageItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: AppColors.darkBrown
                                      .withValues(alpha: 0.15),
                                  thickness: 1,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final event = _currentPageItems[index];
                                  return AdminListRow(
                                    leading: AdminThumbnail(
                                      imageUrl: event.imageUrl,
                                      fallbackIcon: Icons.event_outlined,
                                    ),
                                    columns: [
                                      AdminColumn(flex: 3, text: event.name),
                                      AdminColumn(flex: 2, text: event.eventCategoryName),
                                      AdminColumn(flex: 2, text: event.organizerName),
                                      AdminColumn(flex: 3, text: _formatDateTime(event)),
                                    ],
                                    actions: [
                                      AdminActionButton(
                                        label: 'Click for more\ndetails',
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EventDetailScreen(eventId: event.id),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            PaginationBar(
                              currentPage: _currentPage,
                              totalPages: _totalPages,
                              onPrevious: () =>
                                  setState(() => _currentPage--),
                              onNext: () => setState(() => _currentPage++),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _closeCategoriesDropdown();
    _searchController.dispose();
    super.dispose();
  }
}


/* ----------------------- ADD EVENT DIALOG ----------------------- */

class _AddEventDialog extends StatefulWidget {
  final List<EventCategory> categories;
  final VoidCallback onCreated;
  const _AddEventDialog({required this.categories, required this.onCreated});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _eventService = EventService();
  final _organizerService = OrganizerService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  List<Organizer> _organizers = [];
  bool _organizersLoading = true;

  EventCategory? _selectedCategory;
  Organizer? _selectedOrganizer;
  int? _selectedEventType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isActive = true;
  File? _selectedImage;
  bool _isLoading = false;

  final LayerLink _categoryLink = LayerLink();
  OverlayEntry? _categoryOverlay;
  bool _categoryOpen = false;

  final LayerLink _organizerLink = LayerLink();
  OverlayEntry? _organizerOverlay;
  bool _organizerOpen = false;

  final LayerLink _eventTypeLink = LayerLink();
  OverlayEntry? _eventTypeOverlay;
  bool _eventTypeOpen = false;

  String? _nameError;
  String? _categoryError;
  String? _organizerError;
  String? _eventTypeError;
  String? _dateError;
  String? _timeError;
  String? _priceError;
  String? _capacityError;
  String? _addressError;
  String? _cityError;
  String? _countryError;

  static const _eventTypeLabels = ['Online', 'InPerson'];

  @override
  void initState() {
    super.initState();
    _loadOrganizers();
  }

  Future<void> _loadOrganizers() async {
    try {
      final organizers = await _organizerService.getOrganizers();
      if (mounted) {
        setState(() {
          _organizers = organizers;
          _organizersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _organizersLoading = false);
    }
  }

  void _closeAll() {
    _closeCategoryDropdown();
    _closeOrganizerDropdown();
    _closeEventTypeDropdown();
  }

  void _closeCategoryDropdown() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    if (mounted) setState(() => _categoryOpen = false);
  }

  void _closeOrganizerDropdown() {
    _organizerOverlay?.remove();
    _organizerOverlay = null;
    if (mounted) setState(() => _organizerOpen = false);
  }

  void _closeEventTypeDropdown() {
    _eventTypeOverlay?.remove();
    _eventTypeOverlay = null;
    if (mounted) setState(() => _eventTypeOpen = false);
  }

  void _toggleCategoryDropdown() {
    if (_categoryOpen) { _closeCategoryDropdown(); return; }
    _closeAll();
    _categoryOverlay = _showOverlayDropdown<EventCategory>(
      link: _categoryLink,
      items: widget.categories,
      selected: _selectedCategory,
      labelFn: (c) => c.name,
      onSelect: (c) => setState(() { _selectedCategory = c; _categoryError = null; }),
      onClose: _closeCategoryDropdown,
    );
    setState(() => _categoryOpen = true);
  }

  void _toggleOrganizerDropdown() {
    if (_organizerOpen) { _closeOrganizerDropdown(); return; }
    _closeAll();
    _organizerOverlay = _showOverlayDropdown<Organizer>(
      link: _organizerLink,
      items: _organizers,
      selected: _selectedOrganizer,
      labelFn: (o) => o.name,
      onSelect: (o) => setState(() { _selectedOrganizer = o; _organizerError = null; }),
      onClose: _closeOrganizerDropdown,
    );
    setState(() => _organizerOpen = true);
  }

  void _toggleEventTypeDropdown() {
    if (_eventTypeOpen) { _closeEventTypeDropdown(); return; }
    _closeAll();
    _eventTypeOverlay = _showOverlayDropdown<int>(
      link: _eventTypeLink,
      items: [0, 1],
      selected: _selectedEventType,
      labelFn: (i) => _eventTypeLabels[i],
      onSelect: (i) => setState(() { _selectedEventType = i; _eventTypeError = null; }),
      onClose: _closeEventTypeDropdown,
    );
    setState(() => _eventTypeOpen = true);
  }

  OverlayEntry _showOverlayDropdown<T>({
    required LayerLink link,
    required List<T> items,
    required T? selected,
    required String Function(T) labelFn,
    required void Function(T) onSelect,
    required void Function() onClose,
  }) {
    final entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox(),
            ),
          ),
          CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            offset: const Offset(0, 44),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 240,
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.lightBrown,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.darkBrown.withValues(alpha: 0.2),
                    height: 1,
                    thickness: 1,
                    indent: 14,
                    endIndent: 14,
                  ),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final isSelected = item == selected;
                    return InkWell(
                      onTap: () { onClose(); onSelect(item); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(
                          labelFn(item).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w500,
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
      ),
    );
    Overlay.of(context).insert(entry);
    return entry;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lightBrown,
            onPrimary: AppColors.darkBrown,
            surface: AppColors.darkBrown,
            onSurface: Colors.white,
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
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lightBrown,
            onPrimary: AppColors.darkBrown,
            surface: AppColors.darkBrown,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _selectedTime = picked; _timeError = null; });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedImage = File(result.files.single.path!));
    }
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
      _addressError = isInPerson && _addressController.text.isEmpty ? 'Required for in-person event' : null;
      _cityError = isInPerson && _cityController.text.isEmpty ? 'Required for in-person event' : null;
      _countryError = isInPerson && _countryController.text.isEmpty ? 'Required for in-person event' : null;
    });

    if ([
      _nameError, _categoryError, _organizerError, _eventTypeError,
      _dateError, _timeError, _priceError, _capacityError,
      _addressError, _cityError, _countryError,
    ].any((e) => e != null)) { return; }

    final price = double.tryParse(_priceController.text);
    final capacity = int.tryParse(_capacityController.text);
    if (price == null) { setState(() => _priceError = 'Invalid number'); return; }
    if (capacity == null) { setState(() => _capacityError = 'Invalid number'); return; }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          imageUrl = await _eventService.uploadImage(
            _selectedImage!,
            category: _selectedCategory?.name,
          );
        } catch (_) {
          imageUrl = null;
        }
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
        'reservedSeats': 0,
        if (_descriptionController.text.isNotEmpty)
          'description': _descriptionController.text.trim(),
        if (_addressController.text.isNotEmpty)
          'address': _addressController.text.trim(),
        if (_cityController.text.isNotEmpty)
          'city': _cityController.text.trim(),
        if (_countryController.text.isNotEmpty)
          'country': _countryController.text.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      await _eventService.createEvent(body);

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.show(context, 'Event created successfully!');
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to create event', isError: true);
      }
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ADD NEW EVENT',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 28),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: [
                        BookFormField(
                          controller: _nameController,
                          hint: 'Name',
                          error: _nameError,
                          onChanged: (_) =>
                              setState(() => _nameError = null),
                        ),
                        const SizedBox(height: 14),
                        BookFormDropdownTrigger(
                          link: _categoryLink,
                          hint: 'Category',
                          selectedLabel: _selectedCategory?.name,
                          isOpen: _categoryOpen,
                          error: _categoryError,
                          onTap: _toggleCategoryDropdown,
                        ),
                        const SizedBox(height: 14),
                        BookFormDropdownTrigger(
                          link: _organizerLink,
                          hint: 'Organizer',
                          selectedLabel: _selectedOrganizer?.name,
                          isOpen: _organizerOpen,
                          error: _organizerError,
                          loading: _organizersLoading,
                          onTap: _toggleOrganizerDropdown,
                        ),
                        const SizedBox(height: 14),
                        BookFormDropdownTrigger(
                          link: _eventTypeLink,
                          hint: 'Event Type',
                          selectedLabel: _selectedEventType != null
                              ? _eventTypeLabels[_selectedEventType!]
                              : null,
                          isOpen: _eventTypeOpen,
                          error: _eventTypeError,
                          onTap: _toggleEventTypeDropdown,
                        ),
                        const SizedBox(height: 14),
                        // Image picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 110,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.lightBrown.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.lightBrown
                                      .withValues(alpha: 0.4)),
                            ),
                            child: _selectedImage != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(7),
                                        child: Image.file(_selectedImage!,
                                            fit: BoxFit.cover),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedImage = null),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                                color: Colors.black45,
                                                shape: BoxShape.circle),
                                            child: const Icon(Icons.close,
                                                color: Colors.white, size: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_outlined,
                                          color: AppColors.lightBrown,
                                          size: 32),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Import picture',
                                        style: TextStyle(
                                          color: AppColors.lightBrown
                                              .withValues(alpha: 0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right column
                  Expanded(
                    child: Column(
                      children: [
                        BookFormField(
                          controller: _descriptionController,
                          hint: 'Description (optional)',
                          maxLines: 3,
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 14),

                        // Date picker
                        FormDateTimeTrigger(
                          label: _selectedDate != null
                              ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                              : 'Event Date',
                          hasValue: _selectedDate != null,
                          error: _dateError,
                          icon: Icons.calendar_today_outlined,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 14),

                        // Time picker
                        FormDateTimeTrigger(
                          label: _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Event Time',
                          hasValue: _selectedTime != null,
                          error: _timeError,
                          icon: Icons.access_time_outlined,
                          onTap: _pickTime,
                        ),
                        const SizedBox(height: 14),

                        BookFormField(
                          controller: _priceController,
                          hint: 'Ticket Price',
                          error: _priceError,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              setState(() => _priceError = null),
                        ),
                        const SizedBox(height: 14),
                        BookFormField(
                          controller: _capacityController,
                          hint: 'Capacity',
                          error: _capacityError,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              setState(() => _capacityError = null),
                        ),
                        const SizedBox(height: 14),
                        BookFormField(
                          controller: _addressController,
                          hint: _selectedEventType == 1 ? 'Address' : 'Address (optional)',
                          error: _addressError,
                          onChanged: (_) => setState(() => _addressError = null),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: BookFormField(
                                controller: _cityController,
                                hint: _selectedEventType == 1 ? 'City' : 'City (optional)',
                                error: _cityError,
                                onChanged: (_) => setState(() => _cityError = null),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: BookFormField(
                                controller: _countryController,
                                hint: _selectedEventType == 1 ? 'Country' : 'Country (optional)',
                                error: _countryError,
                                onChanged: (_) => setState(() => _countryError = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Switch(
                              value: _isActive,
                              onChanged: (v) =>
                                  setState(() => _isActive = v),
                              activeThumbColor: AppColors.lightBrown,
                            ),
                            const SizedBox(width: 8),
                            const Text('Active',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.lightBrown)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightBrown,
                        disabledBackgroundColor:
                            AppColors.lightBrown.withValues(alpha: 0.7),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: AppColors.darkBrown, strokeWidth: 2))
                          : const Text('Submit',
                              style: TextStyle(
                                  color: AppColors.darkBrown,
                                  fontWeight: FontWeight.w700)),
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
    _closeAll();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}

