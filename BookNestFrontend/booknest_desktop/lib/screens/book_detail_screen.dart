import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/book.dart';
import '../models/review.dart';
import '../models/category.dart';
import '../models/author.dart';
import '../services/book_service.dart';
import '../services/category_service.dart';
import '../services/author_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import 'books_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final _bookService = BookService();
  Book? _book;
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _bookService.getBook(widget.bookId),
        _bookService.getBookReviews(widget.bookId),
      ]);
      if (!mounted) return;
      final book = results[0] as Book;
      final rawReviews = results[1] as List<Map<String, dynamic>>;
      setState(() {
        _book = book;
        _reviews = rawReviews.map((r) => Review.fromJson(r)).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load book', isError: true);
      }
    }
  }

  String _fmt(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year}';
  }

  Future<void> _deleteBook() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${_book!.title}"?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _bookService.deleteBook(widget.bookId);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BooksScreen()));
        AppSnackBar.show(context, 'Book deleted successfully');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete book', isError: true);
    }
  }

  Future<void> _deleteReview(int reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete this review?',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _bookService.deleteReview(reviewId);
      if (mounted) {
        AppSnackBar.show(context, 'Review deleted');
        _loadBook();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to delete review', isError: true);
    }
  }

  void _openEditDialog() {
    if (_book == null) return;
    showDialog(
      context: context,
      builder: (_) => _EditBookDialog(book: _book!, onUpdated: _loadBook),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'BOOKS',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
          : _book == null
              ? const Center(child: Text('Book not found.', style: TextStyle(color: AppColors.mediumBrown)))
              : _buildContent(_book!),
    );
  }

  Widget _buildContent(Book book) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const BooksScreen())),
            icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(book),
              const SizedBox(width: 32),
              Expanded(child: _buildDetails(book)),
              const SizedBox(width: 28),
              _buildActionButtons(),
            ],
          ),

          const SizedBox(height: 32),
          _buildReviews(),
        ],
      ),
    );
  }

  Widget _buildCover(Book book) {
    return SizedBox(
      width: 200,
      height: 280,
      child: book.imageUrl != null && book.imageUrl!.isNotEmpty
          ? Image.network(book.imageUrl!, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.book_outlined, color: AppColors.mediumBrown, size: 48))
          : const Icon(Icons.book_outlined, color: AppColors.mediumBrown, size: 48),
    );
  }

  Widget _buildDetails(Book book) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
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
                  DetailRow('Author:', book.author),
                  const SizedBox(height: 10),
                  DetailRow('Category:', book.categories.isNotEmpty ? book.categories.join(', ') : '-'),
                  const SizedBox(height: 10),
                  DetailRow('Price:', '${book.price?.toStringAsFixed(0) ?? '-'} BAM'),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailRow('Date Added:', _fmt(book.publicationDate)),
                  const SizedBox(height: 10),
                  DetailRow('Books Available:', book.stock != null ? '${book.stock}' : '-'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ExpandableDetail('Description:', book.description),
        const SizedBox(height: 10),
        _ExpandableDetail('About the author:', book.authorBiography),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        DetailActionButton(
          icon: Icons.edit_outlined,
          label: 'EDIT BOOK',
          onTap: _openEditDialog,
        ),
        const SizedBox(height: 12),
        DetailActionButton(
          icon: Icons.delete_outline,
          label: 'DELETE BOOK',
          onTap: _deleteBook,
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reviews',
            style: TextStyle(color: AppColors.darkBrown, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              Expanded(flex: 2, child: Text('User', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Rate', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 4, child: Text('Review', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              Expanded(flex: 2, child: Text('Date Added', style: TextStyle(color: AppColors.darkBrown, fontSize: 13, fontWeight: FontWeight.w600))),
              SizedBox(width: 140),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        if (_reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No reviews yet.',
                style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.darkBrown.withValues(alpha: 0.15), thickness: 1, height: 1),
            itemBuilder: (ctx, i) {
              final r = _reviews[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(r.userFullName, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: _StarRow(r.rating)),
                    Expanded(flex: 4, child: Text(r.comment ?? '-', style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                    Expanded(flex: 2, child: Text(_fmt(r.createdAt), style: adminRowStyle)),
                    SizedBox(
                      width: 140,
                      height: 34,
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteReview(r.id),
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: const Text('DELETE REVIEW',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.darkBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/* ---------- helper widgets ---------- */

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
                color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: AppColors.darkBrown, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDetail extends StatefulWidget {
  final String label;
  final String? text;

  const _ExpandableDetail(this.label, this.text);

  @override
  State<_ExpandableDetail> createState() => _ExpandableDetailState();
}

class _ExpandableDetailState extends State<_ExpandableDetail> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text?.trim();
    if (text == null || text.isEmpty) {
      return _DetailRow(widget.label, '-');
    }

    // ~60 chars/line × 3 lines = 180; label takes some first-line space
    final isLong = text.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${widget.label} ',
                style: const TextStyle(
                    color: AppColors.darkBrown, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              TextSpan(
                text: text,
                style: const TextStyle(color: AppColors.darkBrown, fontSize: 15),
              ),
            ],
          ),
        ),
        if (isLong) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'View less' : 'View more',
                style: const TextStyle(
                    color: AppColors.mediumBrown, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;

  const _StarRow(this.rating);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: AppColors.darkBrown,
          size: 17,
        ),
      ),
    );
  }
}

/* ---------- edit dialog ---------- */

class _EditBookDialog extends StatefulWidget {
  final Book book;
  final VoidCallback onUpdated;

  const _EditBookDialog({required this.book, required this.onUpdated});

  @override
  State<_EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<_EditBookDialog> {
  final _bookService = BookService();
  final _categoryService = CategoryService();
  final _authorService = AuthorService();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _pageCountController;

  List<Author> _authors = [];
  List<Category> _categories = [];
  Author? _selectedAuthor;
  List<Category> _selectedCategories = [];
  File? _newImage;
  bool _isLoading = false;
  bool _dataLoading = true;

  final LayerLink _authorLink = LayerLink();
  OverlayEntry? _authorOverlay;
  bool _authorOpen = false;

  final LayerLink _categoryLink = LayerLink();
  OverlayEntry? _categoryOverlay;
  bool _categoryOpen = false;

  String? _titleError;
  String? _authorError;
  String? _categoryError;
  String? _priceError;
  String? _stockError;

  List<Category> get _availableCategories =>
      _categories.where((c) => !_selectedCategories.any((s) => s.id == c.id)).toList();

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleController = TextEditingController(text: b.title);
    _descriptionController = TextEditingController(text: b.description ?? '');
    _priceController = TextEditingController(text: b.price?.toStringAsFixed(0) ?? '');
    _stockController = TextEditingController(text: b.stock?.toString() ?? '');
    _pageCountController = TextEditingController(text: b.pageCount?.toString() ?? '');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _authorService.getAuthors(),
        _categoryService.getCategories(),
      ]);
      if (!mounted) return;
      final authors = results[0] as List<Author>;
      final categories = results[1] as List<Category>;
      setState(() {
        _authors = authors;
        _categories = categories;
        _selectedAuthor = authors.cast<Author?>().firstWhere(
            (a) => a?.id == widget.book.authorId, orElse: () => null);
        _selectedCategories = categories
            .where((c) => widget.book.categoryIds.contains(c.id))
            .toList();
        _dataLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _dataLoading = false);
    }
  }

  void _closeAuthorDropdown() {
    _authorOverlay?.remove();
    _authorOverlay = null;
    if (mounted) setState(() => _authorOpen = false);
  }

  void _closeCategoryDropdown() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    if (mounted) setState(() => _categoryOpen = false);
  }

  OverlayEntry _buildDropdown<T>({
    required LayerLink link,
    required List<T> items,
    required T? selected,
    required String Function(T) labelFn,
    required void Function(T) onSelect,
    required VoidCallback onClose,
  }) {
    final entry = OverlayEntry(
      builder: (_) => Stack(
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
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final isSel = item == selected;
                    return InkWell(
                      onTap: () { onClose(); onSelect(item); },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          labelFn(item).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.w900 : FontWeight.w500,
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

  void _toggleAuthor() {
    if (_authorOpen) {
      _closeAuthorDropdown();
    } else {
      _closeCategoryDropdown();
      _authorOverlay = _buildDropdown<Author>(
        link: _authorLink,
        items: _authors,
        selected: _selectedAuthor,
        labelFn: (a) => a.name,
        onSelect: (a) => setState(() { _selectedAuthor = a; _authorError = null; }),
        onClose: _closeAuthorDropdown,
      );
      setState(() => _authorOpen = true);
    }
  }

  void _toggleCategory() {
    if (_categoryOpen) {
      _closeCategoryDropdown();
    } else {
      if (_availableCategories.isEmpty) return;
      _closeAuthorDropdown();
      _categoryOverlay = _buildDropdown<Category>(
        link: _categoryLink,
        items: _availableCategories,
        selected: null,
        labelFn: (c) => c.name,
        onSelect: (c) => setState(() {
          _selectedCategories.add(c);
          _categoryError = null;
        }),
        onClose: _closeCategoryDropdown,
      );
      setState(() => _categoryOpen = true);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      setState(() => _newImage = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    setState(() {
      _titleError = _titleController.text.isEmpty ? 'Required' : null;
      _authorError = _selectedAuthor == null ? 'Required' : null;
      _categoryError = _selectedCategories.isEmpty ? 'Required' : null;
      _priceError = _priceController.text.isEmpty ? 'Required' : null;
      _stockError = _stockController.text.isEmpty ? 'Required' : null;
    });

    if ([_titleError, _authorError, _categoryError, _priceError, _stockError]
        .any((e) => e != null)) { return; }

    final price = double.tryParse(_priceController.text);
    final stock = int.tryParse(_stockController.text);
    if (price == null) { setState(() => _priceError = 'Invalid number'); return; }
    if (stock == null) { setState(() => _stockError = 'Invalid number'); return; }

    setState(() => _isLoading = true);
    try {
      String? coverUrl = widget.book.imageUrl;
      if (_newImage != null) {
        try {
          coverUrl = await _bookService.uploadCover(
              _newImage!, category: _selectedCategories.firstOrNull?.name);
        } catch (_) {}
      }

      final body = <String, dynamic>{
        'title': _titleController.text,
        'authorId': _selectedAuthor!.id,
        'description': _descriptionController.text,
        'price': price,
        'stock': stock,
        'categoryIds': _selectedCategories.map((c) => c.id).toList(),
        if (coverUrl != null) 'coverImageUrl': coverUrl,
      };
      if (_pageCountController.text.isNotEmpty) {
        body['pageCount'] = int.tryParse(_pageCountController.text);
      }

      await _bookService.updateBook(widget.book.id, body);
      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.show(context, 'Book updated successfully!');
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update book', isError: true);
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
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _dataLoading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(color: AppColors.lightBrown)))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'EDIT BOOK',
                      style: TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              BookFormField(controller: _titleController, hint: 'Title', error: _titleError, onChanged: (_) => setState(() => _titleError = null)),
                              const SizedBox(height: 16),
                              BookFormDropdownTrigger(link: _authorLink, hint: 'Author', selectedLabel: _selectedAuthor?.name, isOpen: _authorOpen, error: _authorError, onTap: _toggleAuthor),
                              const SizedBox(height: 16),
                              _CategoryChipsField(
                                link: _categoryLink,
                                selected: _selectedCategories,
                                hasMore: _availableCategories.isNotEmpty,
                                isOpen: _categoryOpen,
                                error: _categoryError,
                                onAdd: _toggleCategory,
                                onRemove: (c) => setState(() {
                                  _selectedCategories.remove(c);
                                  if (_selectedCategories.isEmpty) {
                                    _categoryError = 'Required';
                                  }
                                }),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: double.infinity,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBrown.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.4)),
                                  ),
                                  child: _newImage != null
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            ClipRRect(
                                                borderRadius: BorderRadius.circular(7),
                                                child: Image.file(_newImage!, fit: BoxFit.cover)),
                                            Positioned(
                                              top: 4, right: 4,
                                              child: GestureDetector(
                                                onTap: () => setState(() => _newImage = null),
                                                child: Container(
                                                  decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : widget.book.imageUrl != null
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                    borderRadius: BorderRadius.circular(7),
                                                    child: Image.network(widget.book.imageUrl!, fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => const Icon(Icons.book_outlined, color: AppColors.lightBrown, size: 32))),
                                                Positioned(
                                                  bottom: 0, left: 0, right: 0,
                                                  child: Container(
                                                    color: Colors.black45,
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: const Text('Tap to change', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11)),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.image_outlined, color: AppColors.lightBrown, size: 32),
                                                const SizedBox(height: 6),
                                                Text('Import picture', style: TextStyle(color: AppColors.lightBrown.withValues(alpha: 0.8), fontSize: 13)),
                                              ],
                                            ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            children: [
                              BookFormField(controller: _descriptionController, hint: 'Description', maxLines: 3, onChanged: (_) {}),
                              const SizedBox(height: 16),
                              BookFormField(controller: _priceController, hint: 'Price', error: _priceError, keyboardType: TextInputType.number, onChanged: (_) => setState(() => _priceError = null)),
                              const SizedBox(height: 16),
                              BookFormField(controller: _stockController, hint: 'Stock', error: _stockError, keyboardType: TextInputType.number, onChanged: (_) => setState(() => _stockError = null)),
                              const SizedBox(height: 16),
                              BookFormField(controller: _pageCountController, hint: 'Page count (optional)', keyboardType: TextInputType.number, onChanged: (_) {}),
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
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(color: AppColors.darkBrown, strokeWidth: 2))
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
    _closeAuthorDropdown();
    _closeCategoryDropdown();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _pageCountController.dispose();
    super.dispose();
  }
}

class _CategoryChipsField extends StatelessWidget {
  final LayerLink link;
  final List<Category> selected;
  final bool hasMore;
  final bool isOpen;
  final String? error;
  final VoidCallback onAdd;
  final void Function(Category) onRemove;

  const _CategoryChipsField({
    required this.link,
    required this.selected,
    required this.hasMore,
    required this.isOpen,
    this.error,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            color: AppColors.lightBrown.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: error != null
                  ? Colors.red.withValues(alpha: 0.7)
                  : AppColors.lightBrown.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...selected.map((c) => _Chip(category: c, onRemove: onRemove)),
              if (hasMore)
                CompositedTransformTarget(
                  link: link,
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? AppColors.lightBrown.withValues(alpha: 0.5)
                            : AppColors.lightBrown.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Add category',
                              style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (selected.isEmpty && !hasMore)
                Text('No categories available',
                    style: TextStyle(
                        color: AppColors.lightBrown.withValues(alpha: 0.6), fontSize: 13)),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final Category category;
  final void Function(Category) onRemove;

  const _Chip({required this.category, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.lightBrown.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.name,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onRemove(category),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

