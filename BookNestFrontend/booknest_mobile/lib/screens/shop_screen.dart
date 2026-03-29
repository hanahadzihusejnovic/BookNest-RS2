import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';
import '../services/category_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import 'category_screen.dart';
import '../screens/book_details_screen.dart';
import '../widgets/book_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _bookService = BookService();
  final _categoryService = CategoryService();

  List<Book> _recommendedBooks = [];
  List<Book> _filteredRecommended = [];
  List<Category> _categories = [];
  final Map<int, List<Book>> _booksByCategory = {};
  final Map<int, List<Book>> _filteredByCategory = {};

  bool _isLoading = true;
  String? _error;
  int? _selectedCategoryId;
  String _query = "";

  final LayerLink _catLink = LayerLink();
  OverlayEntry? _catOverlay;
  bool _catOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _categoryService.getCategories();
      final recommended = await _bookService.getContentBasedRecommendations();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _recommendedBooks = recommended;
        _filteredRecommended = recommended;
        _isLoading = false;
      });

      final defaultCategory = _categories.firstWhere(
        (c) => c.name.toLowerCase() == 'fiction',
        orElse: () => _categories.first,
      );

      await _loadBooksForCategory(defaultCategory.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _categories = Category.getDummyCategories();
        _recommendedBooks = [];
        _filteredRecommended = [];
        _isLoading = false;
      });

      if (_categories.isNotEmpty) {
        await _loadBooksForCategory(_categories.first.id);
      }
    }
  }

  Future<void> _loadBooksForCategory(int categoryId) async {
    if (_booksByCategory.containsKey(categoryId)) {
      if (!mounted) return;
      setState(() => _selectedCategoryId = categoryId);
      return;
    }

    try {
      final books =
          await _bookService.getBooksByCategory(categoryId, pageSize: 6);
      if (!mounted) return;
      setState(() {
        _booksByCategory[categoryId] = books;
        _filteredByCategory[categoryId] = books;
        _selectedCategoryId = categoryId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _selectedCategoryId = categoryId);
    }
  }

  Category? get _selectedCategory {
    if (_selectedCategoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == _selectedCategoryId);
    } catch (_) {
      return null;
    }
  }

  void _applySearch() {
    final q = _query.trim().toLowerCase();
    setState(() {
      _filteredRecommended = q.isEmpty
          ? _recommendedBooks
          : _recommendedBooks.where((b) {
              return b.title.toLowerCase().contains(q) ||
                  b.author.toLowerCase().contains(q);
            }).toList();

      if (_selectedCategoryId != null &&
          _booksByCategory.containsKey(_selectedCategoryId)) {
        _filteredByCategory[_selectedCategoryId!] = q.isEmpty
            ? _booksByCategory[_selectedCategoryId!]!
            : _booksByCategory[_selectedCategoryId!]!.where((b) {
                return b.title.toLowerCase().contains(q) ||
                    b.author.toLowerCase().contains(q);
              }).toList();
      }
    });
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
    setState(() => _catOpen = false);
  }

  void _showCategoriesDropdown() {
    if (_categories.isEmpty) return;

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
              offset: const Offset(-6, 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 140,
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppColors.darkBrown,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => Divider(
                      color: AppColors.pageBg,
                      height: 1,
                      thickness: 1,
                      indent: 14,
                      endIndent: 14,
                    ),
                    itemBuilder: (context, i) {
                      final c = _categories[i];
                      final selected = c.id == _selectedCategoryId;

                      return InkWell(
                        onTap: () async {
                          _closeCategoriesDropdown();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CategoryScreen(category: c),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            c.name.toUpperCase(),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.pageBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.darkBrown),
        ),
      );
    }

    final recommended = _filteredRecommended.take(6).toList();
    final cat = _selectedCategory;
    final categoryBooks = _selectedCategoryId != null
        ? (_filteredByCategory[_selectedCategoryId] ?? [])
        : <Book>[];

    return AppLayout(
      pageTitle: 'SHOP',
      showCartFavTbr: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (_catOpen) _closeCategoriesDropdown();
          return false;
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SearchBar(
                hint: "Search by book name or author",
                onChanged: (v) {
                  _query = v;
                  _applySearch();
                },
              ),

              const SizedBox(height: 12),

              CompositedTransformTarget(
                link: _catLink,
                child: InkWell(
                  onTap: _toggleCategoriesDropdown,
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      Text(
                        "Categories",
                        style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
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

              const SizedBox(height: 10),

              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recommended for you!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    recommended.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                "No books to show.",
                                style: TextStyle(
                                  color: AppColors.pageBg.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recommended.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.48,
                            ),
                            itemBuilder: (context, index) {
                              final book = recommended[index];
                              return BookCard(
                                title: book.title,
                                author: book.author,
                                imageUrl: book.imageUrl,
                                style: BookCardStyle.details,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookDetailsScreen(book: book),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat == null
                          ? "Top in category!"
                          : "Top in ${cat.name} category!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    categoryBooks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                "No books to show.",
                                style: TextStyle(
                                  color: AppColors.pageBg.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: categoryBooks.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.48,
                            ),
                            itemBuilder: (context, index) {
                              final book = categoryBooks[index];
                              return BookCard(
                                title: book.title,
                                author: book.author,
                                imageUrl: book.imageUrl,
                                style: BookCardStyle.details,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BookDetailsScreen(book: book),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  "⚠️ $_error",
                  style: TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------- WIDGETS ----------------------- */

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

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}