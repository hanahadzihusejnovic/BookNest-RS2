import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';
import '../services/category_service.dart';
import '../widgets/admin_table.dart';
import '../widgets/book_form_widgets.dart';
import '../widgets/pagination_bar.dart';
import 'books_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _categoryService = CategoryService();
  final _bookService = BookService();

  List<Category> _categories = [];
  List<Category> _filtered = [];
  Map<int, int> _bookCounts = {};
  bool _isLoading = true;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<Category> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _pageSize).ceil();

  final _searchController = TextEditingController();

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
      final results = await Future.wait([
        _categoryService.getCategories(),
        _bookService.getBooks(pageSize: 500),
      ]);
      if (!mounted) return;
      final categories = results[0] as List<Category>;
      final books = results[1] as List<Book>;

      final counts = <int, int>{};
      for (final book in books) {
        for (final catId in book.categoryIds) {
          counts[catId] = (counts[catId] ?? 0) + 1;
        }
      }

      setState(() {
        _categories = categories;
        _bookCounts = counts;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load categories', isError: true);
      }
    }
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filtered = q.isEmpty
          ? List.of(_categories)
          : _categories
              .where((c) => c.name.toLowerCase().contains(q))
              .toList();
    });
  }

  void _openDialog({Category? category}) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        category: category,
        categoryService: _categoryService,
        onSaved: _loadData,
      ),
    );
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Delete Category',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete "${category.name}"?',
            style: const TextStyle(color: Colors.white70)),
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
      await _categoryService.deleteCategory(category.id);
      if (mounted) {
        AppSnackBar.show(context, 'Category deleted');
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to delete category',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'BOOK CATEGORIES',
      onBack: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BooksScreen())),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _openDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    'Add New Category',
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
                        hintText: 'Search categories',
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

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  AdminColHeader('Category name', flex: 3),
                  AdminColHeader('Books', flex: 1),
                  SizedBox(width: 76),
                ],
              ),
            ),
            Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.25),
                thickness: 1,
                height: 12),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.darkBrown))
                  : _filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No categories found.',
                            style: TextStyle(
                                color: AppColors.mediumBrown,
                                fontSize: 14),
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
                                  final cat = _currentPageItems[index];
                                  final count = _bookCounts[cat.id] ?? 0;
                                  return AdminListRow(
                                    columns: [
                                      AdminColumn(
                                          flex: 3, text: cat.name),
                                      AdminColumn(
                                          flex: 1,
                                          text: count.toString()),
                                    ],
                                    actions: [
                                      IconButton(
                                        onPressed: () =>
                                            _openDialog(category: cat),
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: AppColors.darkBrown),
                                        tooltip: 'Edit',
                                        constraints:
                                            const BoxConstraints(),
                                        padding:
                                            const EdgeInsets.all(6),
                                        splashColor: Colors.transparent,
                                        highlightColor:
                                            Colors.transparent,
                                        hoverColor: Colors.transparent,
                                      ),
                                      IconButton(
                                        onPressed: () => _delete(cat),
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Color(0xFFE57373)),
                                        tooltip: 'Delete',
                                        constraints:
                                            const BoxConstraints(),
                                        padding:
                                            const EdgeInsets.all(6),
                                        splashColor: Colors.transparent,
                                        highlightColor:
                                            Colors.transparent,
                                        hoverColor: Colors.transparent,
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

// ─── Category Dialog ──────────────────────────────────────────────────────────

class _CategoryDialog extends StatefulWidget {
  final Category? category;
  final CategoryService categoryService;
  final VoidCallback onSaved;

  const _CategoryDialog(
      {this.category,
      required this.categoryService,
      required this.onSaved});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _nameController;
  String? _nameError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Required');
      return;
    }
    setState(() {
      _nameError = null;
      _isLoading = true;
    });
    try {
      if (widget.category == null) {
        await widget.categoryService.createCategory(name);
      } else {
        await widget.categoryService
            .updateCategory(widget.category!.id, name);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        AppSnackBar.show(
            context,
            widget.category == null
                ? 'Category added'
                : 'Category updated');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Failed to save category',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    return Dialog(
      backgroundColor: AppColors.darkBrown,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 380,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdit ? 'EDIT CATEGORY' : 'ADD CATEGORY',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2),
              ),
              const SizedBox(height: 24),
              BookFormField(
                controller: _nameController,
                hint: 'Category name',
                error: _nameError,
                onChanged: (_) =>
                    setState(() => _nameError = null),
              ),
              const SizedBox(height: 24),
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
                        : Text(
                            isEdit ? 'Save' : 'Add',
                            style: const TextStyle(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.w700),
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
}
