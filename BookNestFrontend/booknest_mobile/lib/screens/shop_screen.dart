import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';
import '../services/category_service.dart';
import '../layouts/constants.dart';

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

  // search
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
      print('🔵 SHOP SCREEN: Starting data load...');

      // Paralelno učitaj kategorije i preporučene knjige
      final results = await Future.wait([
        _categoryService.getCategories(),
        _bookService.getRecommendedBooks(pageSize: 6),
      ]);

      final categories = results[0] as List<Category>;
      final recommended = results[1] as List<Book>;

      print('✅ SHOP SCREEN: Got ${categories.length} categories');
      print('✅ SHOP SCREEN: Got ${recommended.length} recommended books');

      setState(() {
        _categories = categories;
        _recommendedBooks = recommended;
        _isLoading = false;
      });

      // Učitaj knjige za prvu kategoriju
      if (_categories.isNotEmpty) {
        await _loadBooksForCategory(_categories.first.id);
      }
    } catch (e, stackTrace) {
      print('❌ SHOP SCREEN: ERROR loading data: $e');
      print('❌ SHOP SCREEN: Stack trace: $stackTrace');

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
    print('🔵 SHOP SCREEN: Loading books for category ID: $categoryId');

    // Ako već imamo učitane knjige za ovu kategoriju, preskoči
    if (_booksByCategory.containsKey(categoryId)) {
      print('⚠️ SHOP SCREEN: Books already loaded for category $categoryId');
      setState(() => _selectedCategoryId = categoryId);
      return;
    }

    try {
      print('🔵 SHOP SCREEN: Fetching books from API...');
      final books = await _bookService.getBooksByCategory(categoryId, pageSize: 12);
      print('✅ SHOP SCREEN: Got ${books.length} books for category $categoryId');

      setState(() {
        _booksByCategory[categoryId] = books;
        _selectedCategoryId = categoryId;
      });
    } catch (e, stackTrace) {
      print('❌ SHOP SCREEN: ERROR loading books for category $categoryId: $e');
      print('❌ SHOP SCREEN: Stack trace: $stackTrace');

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
          // klik vani zatvara
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeCategoriesDropdown,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox(),
            ),
          ),

          // dropdown panel tačno ispod row-a
          CompositedTransformFollower(
            link: _catLink,
            showWhenUnlinked: false,
            offset: const Offset(-6, 24), // spušta ispod "Categories"
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 140, // širina kao na dizajnu (možeš povećati)
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.darkBrown,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final c = _categories[i];
                    final selected = c.id == _selectedCategoryId;

                    return InkWell(
                      onTap: () async {
                        _closeCategoriesDropdown();
                        await _loadBooksForCategory(c.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Text(
                          c.name.toUpperCase(),
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

    final paddingH = 18.0;

    // Primijeni search na recommended knjige
    final recommended = _applySearch(_recommendedBooks).take(6).toList();

    // Primijeni search na knjige iz kategorije
    final cat = _selectedCategory;
    final catBooksRaw = (_selectedCategoryId != null)
        ? (_booksByCategory[_selectedCategoryId] ?? [])
        : <Book>[];
    final categoryBooks = _applySearch(catBooksRaw);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      drawer: _ShopDrawer(onHome: () => Navigator.pop(context)),
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
  onNotification: (n) {
    if (_catOpen) _closeCategoriesDropdown();
    return false;
  },
  child: SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
              // Header: BookNest + menu
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "BookNest",
                          style: TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 0),
                        Text(
                          "World of your stories!",
                          style: TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (ctx) => IconButton(
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                      icon: Icon(Icons.menu,
                          color: AppColors.darkBrown, size: 26),
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // SHOP row + icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "SHOP",
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.shopping_cart_outlined,
                      color: AppColors.darkBrown, size: 22),
                  const SizedBox(width: 10),
                  Icon(Icons.favorite_border,
                      color: AppColors.darkBrown, size: 22),
                  const SizedBox(width: 10),
                  Icon(Icons.bookmark_border,
                      color: AppColors.darkBrown, size: 22),
                ],
              ),

              const SizedBox(height: 10),

              // Search bar
              _SearchBar(
                hint: "Search by name, author, genre",
                onChanged: (v) => setState(() => _query = v),
              ),

              const SizedBox(height: 12),

              // Categories dropdown (otvara bottom sheet)
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
          _catOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          color: AppColors.darkBrown,
          size: 20,
        ),
      ],
    ),
  ),
),

              const SizedBox(height: 10),

              // Recommended card (3 u redu, kao slika)
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

              // Category section: Top in {category} (GRID kao Recommended)
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
    ));
  }
}

/* ----------------------- WIDGETS (DIZAJN) ----------------------- */

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

/* ------------ Drawer ------------ */

class _ShopDrawer extends StatelessWidget {
  final VoidCallback onHome;
  const _ShopDrawer({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkBrown,
      width: MediaQuery.of(context).size.width * 0.72,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "BookNest",
                style: TextStyle(
                  color: AppColors.pageBg,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "World of your stories!",
                style: TextStyle(
                  color: AppColors.pageBg.withOpacity(0.85),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _DrawerItem(
                title: "HOME",
                onTap: () {
                  Navigator.pop(context);
                  onHome();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _DrawerItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.pageBg,
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}