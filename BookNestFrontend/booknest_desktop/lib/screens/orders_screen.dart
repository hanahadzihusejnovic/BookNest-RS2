import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/admin_table.dart';

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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  AdminColHeader('Items', flex: 2),
                  AdminColHeader('User', flex: 3),
                  AdminColHeader('Order Status', flex: 3),
                  AdminColHeader('Order Date', flex: 3),
                  AdminColHeader('Price', flex: 2),
                  SizedBox(width: 120),
                ],
              ),
            ),
            Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
                  : _filteredOrders.isEmpty
                      ? const Center(
                          child: Text('No orders found.',
                              style: TextStyle(color: AppColors.mediumBrown, fontSize: 14)))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: _currentPageItems.length,
                                separatorBuilder: (_, __) => Divider(
                                    color: AppColors.darkBrown.withValues(alpha: 0.15),
                                    thickness: 1,
                                    height: 1),
                                itemBuilder: (context, index) {
                                  final order = _currentPageItems[index];
                                  return AdminListRow(
                                    columns: [
                                      AdminColumn(
                                        flex: 2,
                                        text: '${order.itemCount} ${order.itemCount == 1 ? 'book' : 'books'}',
                                      ),
                                      AdminColumn(flex: 3, text: order.userFullName),
                                      AdminColumn(
                                        flex: 3,
                                        text: order.status,
                                        color: _statusColor(order.status),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      AdminColumn(flex: 3, text: _formatDate(order.orderDate)),
                                      AdminColumn(
                                        flex: 2,
                                        text: '${order.totalPrice.toStringAsFixed(2)} BAM',
                                      ),
                                    ],
                                    actions: const [
                                      AdminActionButton(label: 'Click for more\ndetails'),
                                    ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
