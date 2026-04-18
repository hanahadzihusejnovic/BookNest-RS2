import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../models/author.dart';
import '../services/book_service.dart';
import '../services/category_service.dart';
import '../services/author_service.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/admin_table.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _bookService = BookService();
  final _categoryService = CategoryService();
  final _searchController = TextEditingController();

  List<Book> _allBooks = [];
  List<Book> _filteredBooks = [];
  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isLoading = true;

  final LayerLink _catLink = LayerLink();
  OverlayEntry? _catOverlay;
  bool _catOpen = false;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<Book> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredBooks.length);
    return _filteredBooks.sublist(start, end);
  }

  int get _totalPages => (_filteredBooks.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _bookService.getBooks(pageSize: 500),
        _categoryService.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _allBooks = results[0] as List<Book>;
        _categories = results[1] as List<Category>;
        _filteredBooks = _allBooks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(context, 'Failed to load books', isError: true);
    }
  }

  void _onSearchChanged(String query) {
    _applyFilters(query: query);
  }

  void _onCategoryChanged(Category? category) {
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
      _filteredBooks = _allBooks.where((b) {
        final matchesSearch = q.isEmpty ||
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q);
        final matchesCategory = _selectedCategory == null ||
            b.categories.any((c) =>
                c.toLowerCase() == _selectedCategory!.name.toLowerCase());
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _openAddBookDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddBookDialog(
        categories: _categories,
        onCreated: _loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'BOOKS',
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
                          _catOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: AppColors.darkBrown,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _openAddBookDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    'Add New Book',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
                style: const TextStyle(
                    color: AppColors.darkBrown, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search by title, author',
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
                  AdminColHeader('Title', flex: 3),
                  AdminColHeader('Category', flex: 2),
                  AdminColHeader('Author', flex: 2),
                  AdminColHeader('Stock', flex: 2),
                  SizedBox(width: 120),
                ],
              ),
            ),
            Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.25),
                thickness: 1,
                height: 12),

            // Books list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.darkBrown))
                  : _filteredBooks.isEmpty
                      ? const Center(
                          child: Text(
                            'No books found.',
                            style: TextStyle(
                                color: AppColors.mediumBrown, fontSize: 14),
                          ),
                        )
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
                                  final book = _currentPageItems[index];
                                  return AdminListRow(
                                    leading: AdminThumbnail(
                                      imageUrl: book.imageUrl,
                                      fallbackIcon: Icons.book_outlined,
                                    ),
                                    columns: [
                                      AdminColumn(flex: 3, text: book.title),
                                      AdminColumn(
                                        flex: 2,
                                        text: book.categories.isNotEmpty
                                            ? book.categories.first
                                            : '-',
                                      ),
                                      AdminColumn(flex: 2, text: book.author),
                                      AdminColumn(
                                          flex: 2,
                                          text: book.stock?.toString() ?? '-'),
                                    ],
                                    actions: const [
                                      AdminActionButton(
                                          label: 'Click for more\ndetails'),
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

    final allItems = <Category?>[null, ..._categories];

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
              offset: const Offset(-6, 28),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 160,
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
                              fontWeight: selected
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
        );
      },
    );

    Overlay.of(context).insert(_catOverlay!);
    setState(() => _catOpen = true);
  }

  @override
  void dispose() {
    _closeCategoriesDropdown();
    _searchController.dispose();
    super.dispose();
  }
}

/* ----------------------- ADD BOOK DIALOG ----------------------- */

class _AddBookDialog extends StatefulWidget {
  final List<Category> categories;
  final VoidCallback onCreated;

  const _AddBookDialog({required this.categories, required this.onCreated});

  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  final _bookService = BookService();
  final _authorService = AuthorService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _pageCountController = TextEditingController();

  List<Author> _authors = [];
  Author? _selectedAuthor;
  Category? _selectedCategory;
  File? _selectedImage;
  bool _isLoading = false;
  bool _authorsLoading = true;

  final LayerLink _authorLink = LayerLink();
  OverlayEntry? _authorOverlay;
  bool _authorOpen = false;

  final LayerLink _categoryLink = LayerLink();
  OverlayEntry? _categoryOverlay;
  bool _categoryOpen = false;

  String? _titleError;
  String? _authorError;
  String? _categoryError;
  String? _descriptionError;
  String? _priceError;
  String? _stockError;

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  Future<void> _loadAuthors() async {
    try {
      final authors = await _authorService.getAuthors();
      if (mounted) {
        setState(() {
          _authors = authors;
          _authorsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _authorsLoading = false);
    }
  }

  void _closeAuthorDropdown() {
    _authorOverlay?.remove();
    _authorOverlay = null;
    if (mounted) setState(() => _authorOpen = false);
  }

  void _closeCategoryDialogDropdown() {
    _categoryOverlay?.remove();
    _categoryOverlay = null;
    if (mounted) setState(() => _categoryOpen = false);
  }

  void _toggleAuthorDropdown() {
    if (_authorOpen) {
      _closeAuthorDropdown();
    } else {
      _closeCategoryDialogDropdown();
      _authorOverlay = _showOverlayDropdown<Author>(
        link: _authorLink,
        items: _authors,
        selected: _selectedAuthor,
        labelFn: (a) => a.name,
        onSelect: (a) => setState(() {
          _selectedAuthor = a;
          _authorError = null;
        }),
        onClose: _closeAuthorDropdown,
      );
      setState(() => _authorOpen = true);
    }
  }

  void _toggleCategoryDialogDropdown() {
    if (_categoryOpen) {
      _closeCategoryDialogDropdown();
    } else {
      _closeAuthorDropdown();
      _categoryOverlay = _showOverlayDropdown<Category>(
        link: _categoryLink,
        items: widget.categories,
        selected: _selectedCategory,
        labelFn: (c) => c.name,
        onSelect: (c) => setState(() {
          _selectedCategory = c;
          _categoryError = null;
        }),
        onClose: _closeCategoryDialogDropdown,
      );
      setState(() => _categoryOpen = true);
    }
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
                      onTap: () {
                        onClose();
                        onSelect(item);
                      },
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

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedImage = File(result.files.single.path!));
    }
  }

  Future<void> _submit() async {
    setState(() {
      _titleError = _titleController.text.isEmpty ? 'Required' : null;
      _authorError = _selectedAuthor == null ? 'Required' : null;
      _categoryError = _selectedCategory == null ? 'Required' : null;
      _descriptionError =
          _descriptionController.text.isEmpty ? 'Required' : null;
      _priceError = _priceController.text.isEmpty ? 'Required' : null;
      _stockError = _stockController.text.isEmpty ? 'Required' : null;
    });

    if ([
      _titleError,
      _authorError,
      _categoryError,
      _descriptionError,
      _priceError,
      _stockError
    ].any((e) => e != null)) { return; }

    final price = double.tryParse(_priceController.text);
    final stock = int.tryParse(_stockController.text);

    if (price == null) {
      setState(() => _priceError = 'Invalid number');
      return;
    }
    if (stock == null) {
      setState(() => _stockError = 'Invalid number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? coverUrl;
      if (_selectedImage != null) {
        try {
          coverUrl = await _bookService.uploadCover(
            _selectedImage!,
            category: _selectedCategory?.name,
          );
        } catch (_) {
          coverUrl = null;
        }
      }

      final body = <String, dynamic>{
        'title': _titleController.text,
        'authorId': _selectedAuthor!.id,
        'description': _descriptionController.text,
        'price': price,
        'stock': stock,
        'categoryIds': [_selectedCategory!.id],
        if (coverUrl != null) 'coverImageUrl': coverUrl,
      };
      if (_pageCountController.text.isNotEmpty) {
        body['pageCount'] = int.tryParse(_pageCountController.text);
      }

      await _bookService.createBook(body);

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.show(context, 'Book created successfully!');
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to create book', isError: true);
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
        width: 600,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'ADD NEW BOOK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 28),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    child: Column(
                      children: [
                        _BookField(
                          controller: _titleController,
                          hint: 'Title',
                          error: _titleError,
                          onChanged: (_) =>
                              setState(() => _titleError = null),
                        ),
                        const SizedBox(height: 16),
                        _OverlayDropdownTrigger(
                          link: _authorLink,
                          hint: 'Author',
                          selectedLabel: _selectedAuthor?.name,
                          isOpen: _authorOpen,
                          error: _authorError,
                          loading: _authorsLoading,
                          onTap: _toggleAuthorDropdown,
                        ),
                        const SizedBox(height: 16),
                        _OverlayDropdownTrigger(
                          link: _categoryLink,
                          hint: 'Category',
                          selectedLabel: _selectedCategory?.name,
                          isOpen: _categoryOpen,
                          error: _categoryError,
                          onTap: _toggleCategoryDialogDropdown,
                        ),
                        const SizedBox(height: 16),

                        // Image picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppColors.lightBrown
                                  .withValues(alpha: 0.25),
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
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                color: Colors.white,
                                                size: 16),
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
                        _BookField(
                          controller: _descriptionController,
                          hint: 'Description',
                          error: _descriptionError,
                          maxLines: 3,
                          onChanged: (_) =>
                              setState(() => _descriptionError = null),
                        ),
                        const SizedBox(height: 16),
                        _BookField(
                          controller: _priceController,
                          hint: 'Price',
                          error: _priceError,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              setState(() => _priceError = null),
                        ),
                        const SizedBox(height: 16),
                        _BookField(
                          controller: _stockController,
                          hint: 'Stock',
                          error: _stockError,
                          keyboardType: TextInputType.number,
                          onChanged: (_) =>
                              setState(() => _stockError = null),
                        ),
                        const SizedBox(height: 16),
                        _BookField(
                          controller: _pageCountController,
                          hint: 'Page count (optional)',
                          keyboardType: TextInputType.number,
                          onChanged: (_) {},
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
                        disabledBackgroundColor: AppColors.lightBrown.withValues(alpha: 0.7),
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
                                  color: AppColors.darkBrown,
                                  strokeWidth: 2))
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
    _closeAuthorDropdown();
    _closeCategoryDialogDropdown();
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _pageCountController.dispose();
    super.dispose();
  }
}

/* ----------------------- BOOK FIELD ----------------------- */

class _BookField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? error;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;

  const _BookField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.error,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: error != null
              ? Colors.red.shade300
              : Colors.white.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.lightBrown.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? Colors.red.shade300 : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: error != null ? Colors.red.shade300 : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBrown),
        ),
        errorText: error,
        errorStyle: TextStyle(color: Colors.red.shade300, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

/* ----------------------- OVERLAY DROPDOWN TRIGGER ----------------------- */

class _OverlayDropdownTrigger extends StatelessWidget {
  final LayerLink link;
  final String hint;
  final String? selectedLabel;
  final bool isOpen;
  final String? error;
  final bool loading;
  final VoidCallback onTap;

  const _OverlayDropdownTrigger({
    required this.link,
    required this.hint,
    required this.isOpen,
    required this.onTap,
    this.selectedLabel,
    this.error,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: link,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: error != null
                      ? Colors.red.shade300
                      : Colors.transparent,
                ),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: AppColors.lightBrown, strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedLabel ?? hint,
                            style: TextStyle(
                              color: selectedLabel != null
                                  ? Colors.white
                                  : error != null
                                      ? Colors.red.shade300
                                      : Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(
                          isOpen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: AppColors.lightBrown,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(error!,
              style:
                  TextStyle(fontSize: 11, color: Colors.red.shade300)),
        ],
      ],
    );
  }
}
