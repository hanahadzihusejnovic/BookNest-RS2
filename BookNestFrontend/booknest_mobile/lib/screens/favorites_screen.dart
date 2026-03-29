import 'package:flutter/material.dart';
import '../models/favorite.dart';
import '../services/favorite_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../widgets/book_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _favoriteService = FavoriteService();
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  String? _error;

  // Pagination
  static const int _pageSize = 9;
  int _currentPage = 0;

  List<FavoriteModel> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _favorites.length);
    return _favorites.sublist(start, end);
  }

  int get _totalPages => (_favorites.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteService.getMyFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(FavoriteModel item) async {
    try {
      await _favoriteService.removeFromFavoritesById(item.bookId);
      setState(() {
        _favorites.removeWhere((f) => f.id == item.id);
        if (_currentPage > 0 && _currentPage >= _totalPages) {
          _currentPage--;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'FAVORITES',
      showCartFavTbr: false,
      showBackButton: true,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkBrown,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : _favorites.isEmpty
                  ? Center(
                      child: Text(
                        'No favorites yet.',
                        style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding:
                                const EdgeInsets.fromLTRB(14, 10, 14, 18),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.mediumBrown,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _currentPageItems.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: 0.48,
                                ),
                                itemBuilder: (context, index) {
                                  final item = _currentPageItems[index];
                                  return BookCard(
                                    title: item.bookTitle,
                                    author: item.bookAuthor,
                                    imageUrl: item.bookImageUrl,
                                    style: BookCardStyle.remove,
                                    onTap: () => _removeFavorite(item),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (_totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: _currentPage > 0
                                        ? AppColors.darkBrown
                                        : AppColors.darkBrown.withOpacity(0.3),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${_currentPage + 1}',
                                  style: TextStyle(
                                    color: AppColors.darkBrown,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _currentPage < _totalPages - 1
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                  child: Icon(
                                    Icons.arrow_forward,
                                    color: _currentPage < _totalPages - 1
                                        ? AppColors.darkBrown
                                        : AppColors.darkBrown.withOpacity(0.3),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
    );
  }
}