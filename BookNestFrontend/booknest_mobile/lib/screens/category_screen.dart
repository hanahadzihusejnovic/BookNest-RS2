import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';
import '../layouts/constants.dart';

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

  List<Book> _books = [];
  bool _isLoading = true;
  String? _error;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    try {
      print('🔵 CATEGORY SCREEN: Loading books for ${widget.category.name}');
      final books = await _bookService.getBooksByCategory(
        widget.category.id,
        pageSize: 50, // Učitaj sve knjige
      );

      setState(() {
        _books = books;
        _isLoading = false;
      });

      print('✅ CATEGORY SCREEN: Loaded ${books.length} books');
    } catch (e) {
      print('❌ CATEGORY SCREEN: Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Book> get _filteredBooks {
    if (_query.isEmpty) return _books;
    final q = _query.toLowerCase();
    return _books.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final paddingH = 18.0;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + Title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back,
                            color: AppColors.darkBrown, size: 26),
                        splashRadius: 20,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BookNest",
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              "World of your stories!",
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icons
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

                  // Category name
                  Text(
                    "${widget.category.name} category",
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Search bar
                  _SearchBar(
                    hint: "Search by name, author...",
                    onChanged: (v) => setState(() => _query = v),
                  ),

                  const SizedBox(height: 10),

                  // Filter button (optional - za sad samo tekst)
                  Row(
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
                      Icon(Icons.filter_list,
                          color: AppColors.darkBrown, size: 18),
                    ],
                  ),
                ],
              ),
            ),

            // Content
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
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: EdgeInsets.symmetric(
                                  horizontal: paddingH, vertical: 10),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.58,
                              ),
                              itemCount: _filteredBooks.length,
                              itemBuilder: (context, index) {
                                final book = _filteredBooks[index];
                                return _CategoryBookCard(
                                  book: book,
                                  onTap: () {
                                    // TODO: Navigate to book details
                                  },
                                );
                              },
                            ),
            ),
          ],
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

class _CategoryBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _CategoryBookCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightBrown.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book cover
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                    ? Image.network(
                        book.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.pageBg.withOpacity(0.7),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.darkBrown.withOpacity(0.5),
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.pageBg.withOpacity(0.7),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.darkBrown.withOpacity(0.5),
                          size: 32,
                        ),
                      ),
              ),
            ),

            // Book info + icons
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkBrown.withOpacity(0.7),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Icons row (cart, heart, bookmark)
                  Row(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          color: AppColors.darkBrown, size: 14),
                      const SizedBox(width: 6),
                      Icon(Icons.favorite_border,
                          color: AppColors.darkBrown, size: 14),
                      const SizedBox(width: 6),
                      Icon(Icons.bookmark_border,
                          color: AppColors.darkBrown, size: 14),
                    ],
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