import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/organizer.dart';
import '../services/organizer_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import '../widgets/pagination_bar.dart';
import 'events_screen.dart';
import 'organizer_detail_screen.dart';

class OrganizersScreen extends StatefulWidget {
  const OrganizersScreen({super.key});

  @override
  State<OrganizersScreen> createState() => _OrganizersScreenState();
}

class _OrganizersScreenState extends State<OrganizersScreen> {
  final _organizerService = OrganizerService();
  final _searchController = TextEditingController();

  List<Organizer> _allOrganizers = [];
  List<Organizer> _filtered = [];
  bool _isLoading = true;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<Organizer> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final organizers = await _organizerService.getOrganizers();
      if (!mounted) return;
      setState(() {
        _allOrganizers = organizers;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load organizers',
            isError: true);
      }
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filtered = q.isEmpty
          ? List.of(_allOrganizers)
          : _allOrganizers
              .where((o) =>
                  o.firstName.toLowerCase().contains(q) ||
                  o.lastName.toLowerCase().contains(q) ||
                  o.contactEmail.toLowerCase().contains(q))
              .toList();
    });
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => OrganizerFormDialog(
        organizerService: _organizerService,
        onSaved: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ORGANIZERS',
      onBack: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EventsScreen())),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _openAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    'Add New Organizer',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.mediumBrown, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilter(),
                      style: const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search by first name, last name and email',
                        hintStyle: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  AdminColHeader('First Name', flex: 2),
                  AdminColHeader('Last Name', flex: 2),
                  AdminColHeader('Contact Email', flex: 3),
                  AdminColHeader('Events', flex: 1),
                  SizedBox(width: 120),
                ],
              ),
            ),
            Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.25),
                thickness: 1,
                height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.darkBrown))
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text('No organizers found.',
                              style: TextStyle(
                                  color: AppColors.mediumBrown,
                                  fontSize: 14)))
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
                                  final o = _currentPageItems[index];
                                  return AdminListRow(
                                    columns: [
                                      AdminColumn(
                                          flex: 2,
                                          text: o.firstName),
                                      AdminColumn(
                                          flex: 2, text: o.lastName),
                                      AdminColumn(
                                          flex: 3,
                                          text: o.contactEmail),
                                      AdminColumn(
                                          flex: 1,
                                          text: o.eventCount
                                              .toString()),
                                    ],
                                    actions: [
                                      AdminActionButton(
                                        label: 'Click for more\ndetails',
                                        onPressed: () =>
                                            Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                OrganizerDetailScreen(
                                                    organizerId: o.id),
                                          ),
                                        ).then((_) => _loadData()),
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
                              onNext: () =>
                                  setState(() => _currentPage++),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}


class OrganizerFormDialog extends StatefulWidget {
  final OrganizerService organizerService;
  final VoidCallback onSaved;

  const OrganizerFormDialog({
    super.key,
    required this.organizerService,
    required this.onSaved,
  });

  @override
  State<OrganizerFormDialog> createState() => _OrganizerFormDialogState();
}

class _OrganizerFormDialogState extends State<OrganizerFormDialog> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(email);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    setState(() {
      _firstNameError =
          _firstNameController.text.trim().isEmpty ? 'First name is required.' : null;
      _lastNameError =
          _lastNameController.text.trim().isEmpty ? 'Last name is required.' : null;
      _emailError = email.isEmpty
          ? 'Contact email is required.'
          : !_isValidEmail(email)
              ? 'Enter a valid email address.'
              : null;
    });
    if (_firstNameError != null ||
        _lastNameError != null ||
        _emailError != null) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.organizerService.createOrganizer(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactEmail: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        AppSnackBar.show(context, 'Organizer added');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to add organizer',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 28),
                  const Expanded(
                    child: Text(
                      'ADD ORGANIZER',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: BookFormField(
                      controller: _firstNameController,
                      hint: 'First Name',
                      error: _firstNameError,
                      onChanged: (_) =>
                          setState(() => _firstNameError = null),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BookFormField(
                      controller: _lastNameController,
                      hint: 'Last Name',
                      error: _lastNameError,
                      onChanged: (_) =>
                          setState(() => _lastNameError = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BookFormField(
                controller: _emailController,
                hint: 'Contact Email',
                error: _emailError,
                onChanged: (_) => setState(() => _emailError = null),
              ),
              const SizedBox(height: 14),
              BookFormField(
                controller: _phoneController,
                hint: 'Phone Number (optional)',
                onChanged: (_) {},
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBrown,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: AppColors.darkBrown,
                                strokeWidth: 2))
                        : const Text('Add',
                            style: TextStyle(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
