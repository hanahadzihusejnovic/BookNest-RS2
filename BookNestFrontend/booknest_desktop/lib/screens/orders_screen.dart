import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/order.dart';
import 'dashboard_screen.dart';
import '../services/order_service.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/admin_table.dart';
import 'order_detail_screen.dart';

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

  Future<void> _generatePdf() async {
    final doc = pw.Document();
    final now = DateTime.now();
    final orders = _filteredOrders;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Orders Report',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                'Generated: ${now.day}.${now.month}.${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text('Total orders: ${orders.length}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
            pw.Divider(),
          ],
        ),
        build: (_) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  '#',
                  'User',
                  'Items',
                  'Status',
                  'Date',
                  'Price (BAM)',
                ].map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    )).toList(),
              ),
              ...orders.asMap().entries.map((entry) {
                final i = entry.key;
                final o = entry.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: i.isEven ? PdfColors.white : PdfColors.grey50),
                  children: [
                    '${i + 1}',
                    o.userFullName,
                    '${o.itemCount} ${o.itemCount == 1 ? 'book' : 'books'}',
                    o.status,
                    _formatDate(o.orderDate),
                    o.totalPrice.toStringAsFixed(2),
                  ].map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: pw.Text(cell,
                            style: const pw.TextStyle(fontSize: 9)),
                      )).toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total revenue: ${orders.fold(0.0, (s, o) => s + o.totalPrice).toStringAsFixed(2)} BAM',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );

    final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
    final filename = 'orders_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
    final file = File('$downloadsPath\\$filename');
    await file.writeAsBytes(await doc.save());
    if (mounted) {
      AppSnackBar.show(context, 'Report saved to Downloads\\$filename');
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFE53935);
      case 'processing':
        return const Color(0xFFFF9800);
      default:
        return AppColors.darkBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ORDERS',
      onBack: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _generatePdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    'Generate PDF Report',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.mediumBrown, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search by user, order status',
                        hintStyle: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
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
                                    actions: [
                                      AdminActionButton(
                                        label: 'Click for more\ndetails',
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => OrderDetailScreen(orderId: order.id),
                                          ),
                                        ),
                                      ),
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
