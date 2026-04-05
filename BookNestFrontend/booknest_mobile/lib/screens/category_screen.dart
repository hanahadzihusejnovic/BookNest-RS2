import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import 'book_details_screen.dart';
import '../widgets/book_card.dart';
import '../screens/cart_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/tbr_screen.dart';
import '../services/cart_service.dart';
import '../services/favorite_service.dart';
import '../services/tbr_service.dart';
import '../widgets/pagination_bar.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _bookService = BookService();
  final _cartService = CartService();
  final _favoriteService = FavoriteService();
  final _tbrService = TBRService();

  List<Book> _books = [];
  List<Book> _filteredBooks = [];
  bool _isLoading = true;
  String? _error;
  String _query = "";

  double? _minPrice;
  double? _maxPrice;
  double? _minRating;

  static const int _pageSize = 12;
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
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _bookService.getBooksByCategory(
        widget.category.id,
        pageSize: 50,
      );

      if (!mounted) return;
      setState(() {
        _books = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart(Book book) async {
  try {
    await _cartService.addItem(book.id, 1);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${book.title} added to cart!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _addToFavorites(Book book) async {
  try {
    await _favoriteService.addToFavorites(book.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${book.title} added to favorites!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showTBRDialog(Book book) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.pageBg,
          title: Text(
            'Add to TBR List',
            style: TextStyle(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReadingStatus.values.map((status) {
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await _tbrService.addToTBR(book.id, status);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${book.title} added to TBR as ${status.label}!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mediumBrown.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.darkBrown),
              ),
            ),
          ],
        );
      },
    );
  }

  void _applySearch() {
    final q = _query.trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filteredBooks = _books.where((b) {
        final matchesSearch = q.isEmpty ||
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q);

        final matchesPrice =
            (_minPrice == null || (b.price ?? 0) >= _minPrice!) &&
                (_maxPrice == null || (b.price ?? 0) <= _maxPrice!);

        final matchesRating =
            _minRating == null || (b.averageRating ?? 0) >= _minRating!;

        return matchesSearch && matchesPrice && matchesRating;
      }).toList();
    });
  }

  void _showFilterDialog() {
    double? tempMinPrice = _minPrice;
    double? tempMaxPrice = _maxPrice;
    double? tempMinRating = _minRating;

    final priceOptions = [
      {'label': 'All', 'min': null, 'max': null},
      {'label': 'Under 15 BAM', 'min': 0.0, 'max': 15.0},
      {'label': '15 - 25 BAM', 'min': 15.0, 'max': 25.0},
      {'label': 'Over 25 BAM', 'min': 25.0, 'max': null},
    ];

    final ratingOptions = [
      {'label': 'All', 'min': null},
      {'label': '3★ and above', 'min': 3.0},
      {'label': '4★ and above', 'min': 4.0},
      {'label': '5★ only', 'min': 5.0},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.pageBg,
              title: Text(
                'Filter books',
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...priceOptions.map((opt) {
                      final isSelected = tempMinPrice == opt['min'] &&
                          tempMaxPrice == opt['max'];
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempMinPrice = opt['min'] as double?;
                            tempMaxPrice = opt['max'] as double?;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkBrown
                                : AppColors.mediumBrown.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opt['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 14),
                    Text(
                      'Rating',
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...ratingOptions.map((opt) {
                      final isSelected = tempMinRating == opt['min'];
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            tempMinRating = opt['min'] as double?;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.darkBrown
                                : AppColors.mediumBrown.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            opt['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.darkBrown,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = null;
                      _maxPrice = null;
                      _minRating = null;
                    });
                    _applySearch();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Reset',
                    style: TextStyle(color: AppColors.darkBrown),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = tempMinPrice;
                      _maxPrice = tempMaxPrice;
                      _minRating = tempMinRating;
                    });
                    _applySearch();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: '${widget.category.name} category',
      showBackButton: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SearchBar(
                  hint: "Search by book name or author",
                  onChanged: (value) {
                    _query = value;
                    _applySearch();
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showFilterDialog,
                      child: Row(
                        children: [
                          Text(
                            "Filter",
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.darkBrown,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const CartScreen())),
                      child: Icon(Icons.shopping_cart_outlined,
                          color: AppColors.darkBrown, size: 20),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const FavoritesScreen())),
                      child: Icon(Icons.favorite_border,
                          color: AppColors.darkBrown, size: 20),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const TBRScreen())),
                      child: Icon(Icons.menu_book,
                          color: AppColors.darkBrown, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.darkBrown,
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "⚠️ $_error",
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _filteredBooks.isEmpty
                        ? Center(
                            child: Text(
                              "No books found",
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.mediumBrown,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: GridView.builder(
                                      itemCount: _currentPageItems.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 0.48,
                                      ),
                                      itemBuilder: (context, index) {
                                        final book = _currentPageItems[index];
                                        return BookCard(
                                          title: book.title,
                                          author: book.author,
                                          imageUrl: book.imageUrl,
                                          price: book.price,
                                          style: BookCardStyle.icons,
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BookDetailsScreen(book: book),
                                            ),
                                          ),
                                          onCartTap: () => _addToCart(book),
                                          onFavTap: () => _addToFavorites(book),
                                          onBookmarkTap: () => _showTBRDialog(book),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                PaginationBar(
                                  currentPage: _currentPage,
                                  totalPages: _totalPages,
                                  onPrevious: () => setState(() => _currentPage--),
                                  onNext: () => setState(() => _currentPage++),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- SEARCH BAR ---------------- */

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