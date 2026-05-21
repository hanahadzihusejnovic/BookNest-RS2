import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/author.dart';
import '../screens/books_screen.dart';
import '../screens/author_detail_screen.dart';
import '../services/author_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import '../widgets/pagination_bar.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({super.key});

  @override
  State<AuthorsScreen> createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final _authorService = AuthorService();
  final _searchController = TextEditingController();

  List<Author> _allAuthors = [];
  List<Author> _filtered = [];
  bool _isLoading = true;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<Author> get _currentPageItems {
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
      final authors = await _authorService.getAuthors();
      if (!mounted) return;
      setState(() {
        _allAuthors = authors;
        _filtered = authors;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load authors', isError: true);
      }
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filtered = q.isEmpty
          ? _allAuthors
          : _allAuthors
              .where((a) =>
                  a.firstName.toLowerCase().contains(q) ||
                  a.lastName.toLowerCase().contains(q))
              .toList();
    });
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _AuthorFormDialog(
        authorService: _authorService,
        onSaved: _loadData,
      ),
    );
  }

  String _fmt(DateTime date) => '${date.day}.${date.month}.${date.year}';

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'AUTHORS',
      onBack: () => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const BooksScreen())),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                  onPressed: _openAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text('Add New Author',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search by first name, last name',
                  hintStyle: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  SizedBox(width: 56),
                  AdminColHeader('First Name', flex: 2),
                  AdminColHeader('Last Name', flex: 2),
                  AdminColHeader('Date of Birth', flex: 2),
                  AdminColHeader('Books', flex: 1),
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
                          child: Text('No authors found.',
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
                                    height: 1),
                                itemBuilder: (context, index) {
                                  final a = _currentPageItems[index];
                                  return AdminListRow(
                                    leading: AdminAvatar(imageUrl: a.imageUrl),
                                    columns: [
                                      AdminColumn(
                                          flex: 2, text: a.firstName),
                                      AdminColumn(
                                          flex: 2, text: a.lastName),
                                      AdminColumn(
                                          flex: 2,
                                          text: _fmt(a.dateOfBirth)),
                                      AdminColumn(
                                          flex: 1,
                                          text: '${a.bookCount}'),
                                    ],
                                    actions: [
                                      AdminActionButton(
                                        label: 'Click for more\ndetails',
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AuthorDetailScreen(
                                                    authorId: a.id),
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

// ─── Add/Edit Dialog ──────────────────────────────────────────────────────────

class _AuthorFormDialog extends StatefulWidget {
  final AuthorService authorService;
  final VoidCallback onSaved;

  const _AuthorFormDialog({
    required this.authorService,
    required this.onSaved,
  });

  @override
  State<_AuthorFormDialog> createState() => _AuthorFormDialogState();
}

class _AuthorFormDialogState extends State<_AuthorFormDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _biographyController;

  DateTime? _dateOfBirth;
  DateTime? _dateOfDeath;

  File? _selectedImage;

  String? _firstNameError;
  String? _lastNameError;
  String? _biographyError;
  String? _dateOfBirthError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _biographyController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  String _fmt(DateTime date) => '${date.day}.${date.month}.${date.year}';

  Future<void> _pickImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
      });
    }
  }

  Future<void> _removeImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Remove photo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to remove the photo?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No',
                  style: TextStyle(color: AppColors.lightBrown))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Yes', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _selectedImage = null);
    }
  }

  Future<void> _pickDate({required bool isDeath}) async {
    final initial = isDeath
        ? (_dateOfDeath ?? DateTime.now())
        : _dateOfBirth;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lightBrown,
            onPrimary: AppColors.darkBrown,
            surface: AppColors.darkBrown,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDeath) {
          _dateOfDeath = picked;
        } else {
          _dateOfBirth = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final biography = _biographyController.text.trim();
    setState(() {
      _firstNameError = firstName.isEmpty ? 'Required' : null;
      _lastNameError = lastName.isEmpty ? 'Required' : null;
      _biographyError = biography.isEmpty ? 'Required' : null;
      _dateOfBirthError = _dateOfBirth == null ? 'Required' : null;
    });
    if (_firstNameError != null ||
        _lastNameError != null ||
        _biographyError != null ||
        _dateOfBirthError != null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await widget.authorService.uploadImage(_selectedImage!);
      }

      await widget.authorService.createAuthor(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _dateOfBirth!,
        dateOfDeath: _dateOfDeath,
        biography: biography,
        imageUrl: imageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        AppSnackBar.show(context, 'Author added');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to save author', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imgProvider;
    if (_selectedImage != null) {
      imgProvider = FileImage(_selectedImage!);
    }
    final hasImage = imgProvider != null;

    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 580,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ADD AUTHOR',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 20),

              // Avatar picker
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor:
                          AppColors.lightBrown.withValues(alpha: 0.3),
                      backgroundImage: imgProvider,
                      child: !hasImage
                          ? const Icon(Icons.person_outline,
                              size: 36, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!hasImage)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Text('Import photo',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        )
                      else ...[
                        GestureDetector(
                          onTap: _pickImage,
                          child: Text('Change photo',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text('  |  ',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 12)),
                        GestureDetector(
                          onTap: _removeImage,
                          child: Text('Remove',
                              style: TextStyle(
                                  color: Colors.red.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BookFormField(
                          controller: _firstNameController,
                          hint: 'First name',
                          error: _firstNameError,
                          onChanged: (_) =>
                              setState(() => _firstNameError = null),
                        ),
                        const SizedBox(height: 14),
                        BookFormField(
                          controller: _lastNameController,
                          hint: 'Last name',
                          error: _lastNameError,
                          onChanged: (_) =>
                              setState(() => _lastNameError = null),
                        ),
                        const SizedBox(height: 14),
                        _DatePickerField(
                          label: 'Date of Birth',
                          value: _dateOfBirth,
                          onTap: () => _pickDate(isDeath: false),
                          formatter: _fmt,
                          error: _dateOfBirthError,
                        ),
                        const SizedBox(height: 14),
                        _DatePickerField(
                          label: 'Date of Death (optional)',
                          value: _dateOfDeath,
                          onTap: () => _pickDate(isDeath: true),
                          formatter: _fmt,
                          onClear: () =>
                              setState(() => _dateOfDeath = null),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: BookFormField(
                      controller: _biographyController,
                      hint: 'Biography',
                      error: _biographyError,
                      maxLines: 9,
                      onChanged: (_) =>
                          setState(() => _biographyError = null),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lightBrown),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(color: AppColors.lightBrown)),
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
                                color: AppColors.darkBrown, strokeWidth: 2))
                        : Text('Add',
                            style: const TextStyle(
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

// ─── Date Picker Field ────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String Function(DateTime) formatter;
  final VoidCallback? onClear;
  final String? error;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.formatter,
    this.onClear,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.lightBrown.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: error != null
              ? Border.all(color: Colors.red.shade300)
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? formatter(value!) : label,
                style: TextStyle(
                  color: value != null
                      ? Colors.white
                      : error != null
                          ? Colors.red.shade300
                          : Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
            if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6)),
              )
            else
              Icon(Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
