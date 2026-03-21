import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/category.dart';
import '../services/book_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import 'book_details_screen.dart';

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
      final books = await _bookService.getBooksByCategory(
        widget.category.id,
        pageSize: 50,
      );

      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
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
    return AppLayout(
      pageTitle: '${widget.category.name} category',
      showCartFavTbr: true,
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
                  hint: "Search by name, author...",
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                const _FilterRow(),
                const SizedBox(height: 12),
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
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.mediumBrown,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: GridView.builder(
                                itemCount: _filteredBooks.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.50,
                                ),
                                itemBuilder: (context, index) {
                                  final book = _filteredBooks[index];
                                  return _CategoryBookCard(
                                    book: book,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookDetailsScreen(book: book),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
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

  const _SearchBar({
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(
          color: AppColors.darkBrown,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.darkBrown.withOpacity(0.35),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/* ---------------- FILTER ROW ---------------- */

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

/* ---------------- BOOK CARD ---------------- */

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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
        decoration: BoxDecoration(
          color: AppColors.pageBg.withOpacity(0.88),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: double.infinity,
                  child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                      ? Image.network(
                          book.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallback(),
                        )
                      : _fallback(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.darkBrown.withOpacity(0.58),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(book.price ?? 0).toStringAsFixed(2)} BAM',
                    style: TextStyle(
                      color: AppColors.darkBrown.withOpacity(0.82),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 12,
                        color: AppColors.darkBrown,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.favorite_border,
                        size: 12,
                        color: AppColors.darkBrown,
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.bookmark_border,
                        size: 12,
                        color: AppColors.darkBrown,
                      ),
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

  Widget _fallback() {
    return Container(
      color: Colors.white.withOpacity(0.45),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.darkBrown.withOpacity(0.5),
        size: 28,
      ),
    );
  }
}