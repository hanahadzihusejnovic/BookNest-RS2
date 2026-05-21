import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/event.dart';
import '../models/organizer.dart';
import '../services/event_service.dart';
import '../services/organizer_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import 'organizers_screen.dart';

class OrganizerDetailScreen extends StatefulWidget {
  final int organizerId;

  const OrganizerDetailScreen({super.key, required this.organizerId});

  @override
  State<OrganizerDetailScreen> createState() => _OrganizerDetailScreenState();
}

class _OrganizerDetailScreenState extends State<OrganizerDetailScreen> {
  final _organizerService = OrganizerService();
  final _eventService = EventService();
  Organizer? _organizer;
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizer();
  }

  Future<void> _loadOrganizer() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _organizerService.getOrganizer(widget.organizerId),
        _eventService.getEvents(organizerId: widget.organizerId),
      ]);
      if (!mounted) return;
      setState(() {
        _organizer = results[0] as Organizer;
        _events = results[1] as List<Event>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load organizer',
            isError: true);
      }
    }
  }

  Future<void> _deleteOrganizer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Organizer',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${_organizer!.name}"?',
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.lightBrown)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _organizerService.deleteOrganizer(widget.organizerId);
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const OrganizersScreen()));
        AppSnackBar.show(context, 'Organizer deleted');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to delete organizer',
            isError: true);
      }
    }
  }

  void _openEditDialog() {
    if (_organizer == null) return;
    showDialog(
      context: context,
      builder: (_) => _EditOrganizerDialog(
        organizer: _organizer!,
        organizerService: _organizerService,
        onUpdated: _loadOrganizer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ORGANIZERS',
      onBack: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrganizersScreen())),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.darkBrown))
          : _organizer == null
              ? const Center(
                  child: Text('Organizer not found.',
                      style: TextStyle(
                          color: AppColors.mediumBrown)))
              : _buildContent(_organizer!),
    );
  }

  Widget _buildContent(Organizer organizer) {
    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDetails(organizer)),
              const SizedBox(width: 28),
              _buildActionButtons(),
            ],
          ),
          const SizedBox(height: 32),
          _buildEvents(organizer),
        ],
      ),
    );
  }

  Widget _buildDetails(Organizer organizer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          organizer.name,
          style: const TextStyle(
              color: AppColors.darkBrown,
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailRow('First Name:', organizer.firstName),
                  const SizedBox(height: 10),
                  DetailRow('Last Name:', organizer.lastName),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailRow('Contact Email:', organizer.contactEmail),
                  const SizedBox(height: 10),
                  DetailRow(
                      'Phone Number:',
                      organizer.phoneNumber?.isNotEmpty == true
                          ? organizer.phoneNumber!
                          : '-'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        DetailActionButton(
          icon: Icons.edit_outlined,
          label: 'EDIT ORGANIZER',
          onTap: _openEditDialog,
          width: 200,
        ),
        const SizedBox(height: 12),
        DetailActionButton(
          icon: Icons.delete_outline,
          label: 'DELETE ORGANIZER',
          onTap: _deleteOrganizer,
          width: 200,
        ),
      ],
    );
  }

  Widget _buildEvents(Organizer organizer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Events',
            style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              SizedBox(width: 56),
              AdminColHeader('Name', flex: 3),
              AdminColHeader('Category', flex: 2),
              AdminColHeader('Date', flex: 2),
            ],
          ),
        ),
        Divider(
            color: AppColors.darkBrown.withValues(alpha: 0.25),
            thickness: 1,
            height: 12),
        if (_events.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No events.',
                style: TextStyle(
                    color: AppColors.mediumBrown, fontSize: 14)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _events.length,
            separatorBuilder: (_, __) => Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.15),
                thickness: 1,
                height: 1),
            itemBuilder: (ctx, i) {
              final e = _events[i];
              final d = e.eventDate;
              final dateStr = '${d.day}.${d.month}.${d.year}';
              return AdminListRow(
                leading: AdminThumbnail(
                  imageUrl: e.imageUrl,
                  fallbackIcon: Icons.event_outlined,
                ),
                columns: [
                  AdminColumn(flex: 3, text: e.name),
                  AdminColumn(
                      flex: 2,
                      text: e.eventCategoryName.isNotEmpty
                          ? e.eventCategoryName
                          : '-'),
                  AdminColumn(flex: 2, text: dateStr),
                ],
                actions: const [],
              );
            },
          ),
      ],
    );
  }
}

// ─── Edit Dialog ──────────────────────────────────────────────────────────────

class _EditOrganizerDialog extends StatefulWidget {
  final Organizer organizer;
  final OrganizerService organizerService;
  final VoidCallback onUpdated;

  const _EditOrganizerDialog(
      {required this.organizer,
      required this.organizerService,
      required this.onUpdated});

  @override
  State<_EditOrganizerDialog> createState() =>
      _EditOrganizerDialogState();
}

class _EditOrganizerDialogState extends State<_EditOrganizerDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.organizer.firstName);
    _lastNameController =
        TextEditingController(text: widget.organizer.lastName);
    _emailController =
        TextEditingController(text: widget.organizer.contactEmail);
    _phoneController =
        TextEditingController(text: widget.organizer.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _firstNameError =
          _firstNameController.text.trim().isEmpty ? 'Required' : null;
      _lastNameError =
          _lastNameController.text.trim().isEmpty ? 'Required' : null;
      _emailError =
          _emailController.text.trim().isEmpty ? 'Required' : null;
    });
    if (_firstNameError != null ||
        _lastNameError != null ||
        _emailError != null) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.organizerService.updateOrganizer(
        widget.organizer.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        contactEmail: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        AppSnackBar.show(context, 'Organizer updated');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to update organizer',
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
              const Text(
                'EDIT ORGANIZER',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2),
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
                onChanged: (_) =>
                    setState(() => _emailError = null),
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
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.lightBrown),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppColors.lightBrown)),
                  ),
                  const SizedBox(width: 12),
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
                        : const Text('Save',
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
