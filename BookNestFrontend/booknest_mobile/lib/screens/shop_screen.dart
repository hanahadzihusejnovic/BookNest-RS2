import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';
import '../services/category_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import 'category_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _bookService = BookService();
  final _categoryService = CategoryService();

  List<Book> _recommendedBooks = [];
  List<Category> _categories = [];
  final Map<int, List<Book>> _booksByCategory = {};

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
      final results = await Future.wait([
        _categoryService.getCategories(),
        _bookService.getRecommendedBooks(pageSize: 6),
      ]);

      final categories = results[0] as List<Category>;
      final recommended = results[1] as List<Book>;

      setState(() {
        _categories = categories;
        _recommendedBooks = recommended;
        _isLoading = false;
      });

      if (_categories.isNotEmpty) {
        await _loadBooksForCategory(_categories.first.id);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _categories = Category.getDummyCategories();
        _recommendedBooks = Book.getDummyBooks().take(6).toList();
        _isLoading = false;
      });

      if (_categories.isNotEmpty) {
        await _loadBooksForCategory(_categories.first.id);
      }
    }
  }

  Future<void> _loadBooksForCategory(int categoryId) async {
    if (_booksByCategory.containsKey(categoryId)) {
      setState(() => _selectedCategoryId = categoryId);
      return;
    }

    try {
      final books =
          await _bookService.getBooksByCategory(categoryId, pageSize: 12);
      setState(() {
        _booksByCategory[categoryId] = books;
        _selectedCategoryId = categoryId;
      });
    } catch (e) {
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

  List<Book> _applySearch(List<Book> books) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return books;
    return books.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q);
    }).toList();
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
                              builder: (context) => CategoryScreen(category: c),
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
                              fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
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

    final recommended = _applySearch(_recommendedBooks).take(6).toList();
    final cat = _selectedCategory;
    final catBooksRaw = (_selectedCategoryId != null)
        ? (_booksByCategory[_selectedCategoryId] ?? [])
        : <Book>[];
    final categoryBooks = _applySearch(catBooksRaw);

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
              // Search bar
              _SearchBar(
                hint: "Search by name, author, genre",
                onChanged: (v) => setState(() => _query = v),
              ),

              const SizedBox(height: 12),

              // Categories dropdown
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

              // Recommended
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recommended.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.62,
                      ),
                      itemBuilder: (context, index) {
                        final book = recommended[index];
                        return _ShopBookCard(book: book, onTap: () {});
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Category section
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
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemBuilder: (context, index) {
                              final book = categoryBooks[index];
                              return _ShopBookCard(book: book, onTap: () {});
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

class _ShopBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _ShopBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.pageBg.withOpacity(0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.pageBg.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (book.imageUrl != null && book.imageUrl!.isNotEmpty)
                      ? Image.network(
                          book.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: AppColors.darkBrown.withOpacity(0.65),
                              size: 30,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.darkBrown.withOpacity(0.65),
                            size: 30,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}