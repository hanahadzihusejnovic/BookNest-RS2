import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/pagination_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderService = OrderService();
  final _searchController = TextEditingController();

  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<Order> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredOrders.length);
    return _filteredOrders.sublist(start, end);
  }

  int get _totalPages => (_filteredOrders.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getOrders();
      if (!mounted) return;
      setState(() {
        _allOrders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(context, 'Failed to load orders', isError: true);
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filteredOrders = q.isEmpty
          ? _allOrders
          : _allOrders.where((o) {
              return o.userFullName.toLowerCase().contains(q) ||
                  o.status.toLowerCase().contains(q);
            }).toList();
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year}';

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFE53935);
      case 'processing':
        return const Color(0xFFFF9800);
      default:
        return AppColors.mediumBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ORDERS',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                style: const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search by user, order status',
                  hintStyle: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  _ColHeader('Items', flex: 2),
                  _ColHeader('User', flex: 3),
                  _ColHeader('Order Status', flex: 3),
                  _ColHeader('Order Date', flex: 3),
                  _ColHeader('Price', flex: 2),
                  SizedBox(width: 120),
                ],
              ),
            ),
            Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.25),
                thickness: 1,
                height: 12),

            // Orders list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.darkBrown))
                  : _filteredOrders.isEmpty
                      ? const Center(
                          child: Text('No orders found.',
                              style: TextStyle(
                                  color: AppColors.mediumBrown, fontSize: 14)))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: _currentPageItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: AppColors.darkBrown.withValues(alpha: 0.15),
                                  thickness: 1,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final order = _currentPageItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${order.itemCount} ${order.itemCount == 1 ? 'book' : 'books'}',
                                            style: _rowStyle,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(order.userFullName,
                                              style: _rowStyle,
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            order.status,
                                            style: _rowStyle.copyWith(
                                              color: _statusColor(order.status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(_formatDate(order.orderDate),
                                              style: _rowStyle),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '${order.totalPrice.toStringAsFixed(2)} BAM',
                                            style: _rowStyle,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          height: 34,
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              elevation: 0,
                                              backgroundColor: AppColors.darkBrown,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: const Text(
                                              'Click for more\ndetails',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                height: 1.3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
          ],
        ),
      ),
    );
  }

  static const _rowStyle = TextStyle(
    color: AppColors.darkBrown,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/* ----------------------- COLUMN HEADER ----------------------- */

class _ColHeader extends StatelessWidget {
  final String text;
  final int flex;

  const _ColHeader(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.darkBrown,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
