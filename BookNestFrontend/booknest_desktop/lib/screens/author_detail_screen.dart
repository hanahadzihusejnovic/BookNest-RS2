import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/author.dart';
import '../services/author_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import 'authors_screen.dart';

class AuthorDetailScreen extends StatefulWidget {
  final int authorId;

  const AuthorDetailScreen({super.key, required this.authorId});

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  final _authorService = AuthorService();
  Author? _author;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final author = await _authorService.getAuthor(widget.authorId);
      if (!mounted) return;
      setState(() {
        _author = author;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load author', isError: true);
      }
    }
  }

  String _fmt(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _deleteAuthor() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Author',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${_author!.name}"?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
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
      await _authorService.deleteAuthor(widget.authorId);
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AuthorsScreen()));
        AppSnackBar.show(context, 'Author deleted');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete author', isError: true);
    }
  }

  void _openEditDialog() {
    if (_author == null) return;
    showDialog(
      context: context,
      builder: (_) => _EditAuthorDialog(
        author: _author!,
        authorService: _authorService,
        onUpdated: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'AUTHORS',
      onBack: () => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthorsScreen())),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown))
          : _author == null
              ? const Center(
                  child: Text('Author not found.',
                      style: TextStyle(color: AppColors.mediumBrown)))
              : _buildContent(_author!),
    );
  }

  Widget _buildContent(Author author) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(author),
              const SizedBox(width: 32),
              Expanded(child: _buildDetails(author)),
              const SizedBox(width: 28),
              _buildActionButtons(),
            ],
          ),
          const SizedBox(height: 32),
          _buildBooks(author),
        ],
      ),
    );
  }

  Widget _buildAvatar(Author author) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightBrown.withValues(alpha: 0.3),
      ),
      child: ClipOval(
        child: author.imageUrl != null && author.imageUrl!.isNotEmpty
            ? Image.network(
                author.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_outline,
                    color: AppColors.mediumBrown,
                    size: 72),
              )
            : const Icon(Icons.person_outline,
                color: AppColors.mediumBrown, size: 72),
      ),
    );
  }

  Widget _buildDetails(Author author) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          author.name,
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
                  DetailRow('First Name:', author.firstName),
                  const SizedBox(height: 10),
                  DetailRow('Last Name:', author.lastName),
                  const SizedBox(height: 10),
                  DetailRow('Date of Birth:', _fmt(author.dateOfBirth)),
                  const SizedBox(height: 10),
                  DetailRow('Date of Death:', _fmt(author.dateOfDeath)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailRow('Biography:', author.biography),
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
          label: 'EDIT AUTHOR',
          onTap: _openEditDialog,
          width: 180,
        ),
        const SizedBox(height: 12),
        DetailActionButton(
          icon: Icons.delete_outline,
          label: 'DELETE AUTHOR',
          onTap: _deleteAuthor,
          width: 180,
        ),
      ],
    );
  }

  Widget _buildBooks(Author author) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Books',
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
              Expanded(
                  flex: 3,
                  child: Text('Title',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 2,
                  child: Text('Category',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
              Expanded(
                  flex: 1,
                  child: Text('Price',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
            ],
          ),
        ),
        Divider(
            color: AppColors.darkBrown.withValues(alpha: 0.25),
            thickness: 1,
            height: 12),
        if (author.books.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No books yet.',
                style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: author.books.length,
            separatorBuilder: (_, __) => Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.15),
                thickness: 1,
                height: 1),
            itemBuilder: (ctx, i) {
              final b = author.books[i];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    AdminThumbnail(imageUrl: b.imageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                        flex: 3,
                        child: Text(b.title,
                            style: adminRowStyle,
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 2,
                        child: Text(b.categories.join(', '),
                            style: adminRowStyle,
                            overflow: TextOverflow.ellipsis)),
                    Expanded(
                        flex: 1,
                        child: Text(
                            b.price != null
                                ? '${b.price!.toStringAsFixed(2)} BAM'
                                : '-',
                            style: adminRowStyle)),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─── Edit Dialog ─────────────────────────────────────────────────────────────

class _EditAuthorDialog extends StatefulWidget {
  final Author author;
  final AuthorService authorService;
  final VoidCallback onUpdated;

  const _EditAuthorDialog(
      {required this.author,
      required this.authorService,
      required this.onUpdated});

  @override
  State<_EditAuthorDialog> createState() => _EditAuthorDialogState();
}

class _EditAuthorDialogState extends State<_EditAuthorDialog> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _biographyController;

  late DateTime _dateOfBirth;
  DateTime? _dateOfDeath;

  File? _selectedImage;
  bool _imageDeleted = false;

  String? _firstNameError;
  String? _lastNameError;
  String? _biographyError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.author.firstName);
    _lastNameController =
        TextEditingController(text: widget.author.lastName);
    _biographyController =
        TextEditingController(text: widget.author.biography);
    _dateOfBirth = widget.author.dateOfBirth;
    _dateOfDeath = widget.author.dateOfDeath;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedImage = File(result.files.single.path!);
        _imageDeleted = false;
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
              child: const Text('Yes', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _selectedImage = null;
        _imageDeleted = true;
      });
    }
  }

  String _fmt(DateTime date) => '${date.day}.${date.month}.${date.year}';

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
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
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickDateOfDeath() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfDeath ?? DateTime.now(),
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
    if (picked != null) setState(() => _dateOfDeath = picked);
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final biography = _biographyController.text.trim();
    setState(() {
      _firstNameError = firstName.isEmpty ? 'Required' : null;
      _lastNameError = lastName.isEmpty ? 'Required' : null;
      _biographyError = biography.isEmpty ? 'Required' : null;
    });
    if (_firstNameError != null ||
        _lastNameError != null ||
        _biographyError != null) { return; }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await widget.authorService.uploadImage(_selectedImage!);
      } else if (_imageDeleted) {
        imageUrl = null;
      } else {
        imageUrl = widget.author.imageUrl;
      }

      await widget.authorService.updateAuthor(
        widget.author.id,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: _dateOfBirth,
        dateOfDeath: _dateOfDeath,
        biography: biography,
        imageUrl: imageUrl,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        AppSnackBar.show(context, 'Author updated');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update author', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imgProvider;
    if (_selectedImage != null) {
      imgProvider = FileImage(_selectedImage!);
    } else if (!_imageDeleted && widget.author.imageUrl != null) {
      imgProvider = NetworkImage(widget.author.imageUrl!);
    }
    final hasImage = imgProvider != null;

    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('EDIT AUTHOR',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 20),
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
                      GestureDetector(
                        onTap: _pickImage,
                        child: Text('Change photo',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (hasImage) ...[
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
              const SizedBox(height: 20),
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
                          onTap: _pickDateOfBirth,
                          formatter: _fmt,
                        ),
                        const SizedBox(height: 14),
                        _DatePickerField(
                          label: 'Date of Death (optional)',
                          value: _dateOfDeath,
                          onTap: _pickDateOfDeath,
                          formatter: _fmt,
                          onClear: () => setState(() => _dateOfDeath = null),
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
                      maxLines: 8,
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

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String Function(DateTime) formatter;
  final VoidCallback? onClear;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.formatter,
    this.onClear,
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
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? formatter(value!) : label,
                style: TextStyle(
                  color: value != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ),
            if (value != null && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close,
                    size: 16, color: Colors.white.withValues(alpha: 0.6)),
              )
            else
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
