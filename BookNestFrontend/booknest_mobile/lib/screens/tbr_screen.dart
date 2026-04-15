import 'package:flutter/material.dart';
import '../models/tbr.dart';
import '../services/tbr_service.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../widgets/book_card.dart';
import '../widgets/pagination_bar.dart';

class TBRScreen extends StatefulWidget {
  const TBRScreen({super.key});

  @override
  State<TBRScreen> createState() => _TBRScreenState();
}

class _TBRScreenState extends State<TBRScreen> {
  final _tbrService = TBRService();
  List<TBRItemModel> _allItems = [];
  List<TBRItemModel> _filteredItems = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedStatus; // null = sve

  static const int _pageSize = 12;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'All', 'value': null},
    {'label': 'To Be Read', 'value': 0},
    {'label': 'Reading', 'value': 1},
    {'label': 'Read', 'value': 2},
  ];

  List<TBRItemModel> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredItems.length);
    return _filteredItems.sublist(start, end);
  }

  int get _totalPages => (_filteredItems.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadTBR();
  }

  Future<void> _loadTBR() async {
    try {
      final items = await _tbrService.getMyTBRList();
      setState(() {
        _allItems = items;
        _filteredItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter(int? status) {
    setState(() {
      _selectedStatus = status;
      _currentPage = 0;
      if (status == null) {
        _filteredItems = _allItems;
      } else {
        _filteredItems =
            _allItems.where((i) => i.readingStatus == status).toList();
      }
    });
  }

  Future<void> _removeItem(TBRItemModel item) async {
    try {
      await _tbrService.removeFromTBRById(item.bookId);
      setState(() {
        _allItems.removeWhere((i) => i.id == item.id);
        _filteredItems.removeWhere((i) => i.id == item.id);
        if (_currentPage > 0 && _currentPage >= _totalPages) {
          _currentPage--;
        }
      });
      if (mounted) {
        AppSnackBar.show(context, 'Removed from TBR list!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e);
      }
    }
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0: return 'To Be Read';
      case 1: return 'Reading';
      case 2: return 'Read';
      default: return '';
    }
  }

  void _showFilterMenu(BuildContext buttonContext) {
    final RenderBox? button =
        buttonContext.findRenderObject() as RenderBox?;
    final RenderBox? overlay =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
            button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: buttonContext,
      position: position,
      color: AppColors.pageBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: _statusOptions.map((opt) {
        final isSelected = _selectedStatus == opt['value'];
        return PopupMenuItem<String>(
          value: opt['value'] == null ? 'all' : opt['value'].toString(),
          child: Center(
            child: Text(
              opt['label'],
              style: TextStyle(
                color: AppColors.darkBrown,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected == null) return; // samo dismiss
      if (selected == 'all') {
        _applyFilter(null);
      } else {
        _applyFilter(int.parse(selected));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'TO BE READ LIST',
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
              : _allItems.isEmpty
                  ? Center(
                      child: Text(
                        'Your TBR list is empty.',
                        style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Filter dropdown
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Builder(
                              builder: (buttonContext) => GestureDetector(
                                onTap: () => _showFilterMenu(buttonContext),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkBrown,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedStatus == null
                                            ? 'ALL'
                                            : _statusLabel(_selectedStatus!)
                                                .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.arrow_drop_down,
                                          color: Colors.white, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        Expanded(
                          child: _filteredItems.isEmpty
                              ? Center(
                                  child: Text(
                                    'No books with this status.',
                                    style: TextStyle(
                                      color: AppColors.darkBrown,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.mediumBrown,
                                      borderRadius: BorderRadius.circular(14),
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
                                        final item = _currentPageItems[index];
                                        return BookCard(
                                          title: item.bookTitle,
                                          author: item.bookAuthor,
                                          imageUrl: item.bookImageUrl,
                                          style: BookCardStyle.remove,
                                          statusLabel: _statusLabel(item.readingStatus),
                                          onTap: () => _removeItem(item),
                                        );
                                      },
                                    ),
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
    );
  }
}