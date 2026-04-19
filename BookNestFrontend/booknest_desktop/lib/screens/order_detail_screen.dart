import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/order_detail.dart';
import '../services/order_service.dart';
import '../widgets/admin_table.dart';
import 'orders_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService();
  OrderDetail? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final order = await _orderService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load order', isError: true);
      }
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}.${d.month}.${d.year}';
  }

  static const _orderTransitions = {
    'Pending':    [('Processing', 1), ('Cancelled', 4)],
    'Processing': [('Shipped', 2),    ('Cancelled', 4)],
    'Shipped':    [('Delivered', 3),  ('Cancelled', 4)],
  };

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':  return const Color(0xFF4CAF50);
      case 'cancelled':  return const Color(0xFFE53935);
      case 'processing': return const Color(0xFFFF9800);
      case 'shipped':    return const Color(0xFF2196F3);
      default:           return AppColors.mediumBrown;
    }
  }

  Future<void> _changeStatus() async {
    final order = _order;
    if (order == null) return;
    final options = _orderTransitions[order.status];
    if (options == null || options.isEmpty) return;

    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Change Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((o) => ListTile(
                    title: Text(o.$1, style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(ctx, o.$2),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;
    try {
      await _orderService.updateStatus(order.id, chosen);
      if (mounted) {
        AppSnackBar.show(context, 'Status updated');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update status', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ORDERS',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
          : _order == null
              ? const Center(
                  child: Text('Order not found.',
                      style: TextStyle(color: AppColors.mediumBrown)))
              : _buildContent(_order!),
    );
  }

  Widget _buildContent(OrderDetail order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
            icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 16),
          _buildHeader(order),
          const SizedBox(height: 32),
          _buildOrderItems(order),
        ],
      ),
    );
  }

  Widget _buildHeader(OrderDetail order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.id}',
                style: const TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              _Badge(order.status, color: _statusColor(order.status)),
              const SizedBox(height: 20),
              Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order Info',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 10),
                  DetailRow('User:', order.userFullName),
                  const SizedBox(height: 10),
                  DetailRow('Order Date:', _fmt(order.orderDate)),
                  const SizedBox(height: 10),
                  DetailRow('Shipped Date:', _fmt(order.shippedDate)),
                  const SizedBox(height: 10),
                  DetailRow('Total:', '${order.totalPrice.toStringAsFixed(2)} BAM'),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Info',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 10),
                  DetailRow('Method:', order.payment.paymentMethod),
                  const SizedBox(height: 10),
                  DetailRow('Amount:', '${order.payment.amount.toStringAsFixed(2)} BAM'),
                  const SizedBox(height: 10),
                  DetailRow('Date:', _fmt(order.payment.paymentDate)),
                  const SizedBox(height: 10),
                  DetailRow('Status:', order.payment.isSuccessful ? 'Successful' : 'Failed'),
                  if (order.payment.transactionId != null) ...[
                    const SizedBox(height: 10),
                    DetailRow('Transaction ID:', order.payment.transactionId!),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shipping Info',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 10),
                  DetailRow('Address:', order.shipping.address),
                  const SizedBox(height: 10),
                  DetailRow('City:', order.shipping.city),
                  const SizedBox(height: 10),
                  DetailRow('Country:', order.shipping.country),
                  const SizedBox(height: 10),
                  DetailRow('Postal Code:', order.shipping.postalCode),
                ],
              ),
            ),
          ],
        ),
            ],
          ),
        ),
        const SizedBox(width: 28),
        if (_orderTransitions.containsKey(order.status))
          DetailActionButton(
            icon: Icons.swap_horiz,
            label: 'CHANGE STATUS',
            onTap: _changeStatus,
            width: 185,
          ),
      ],
    );
  }

  Widget _buildOrderItems(OrderDetail order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Items',
            style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              SizedBox(width: 56),
              AdminColHeader('Book Title', flex: 4),
              AdminColHeader('Author', flex: 3),
              AdminColHeader('Qty', flex: 1),
              AdminColHeader('Unit Price', flex: 2),
              AdminColHeader('Subtotal', flex: 2),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.orderItems.length,
          separatorBuilder: (_, __) =>
              Divider(color: AppColors.darkBrown.withValues(alpha: 0.15), thickness: 1, height: 1),
          itemBuilder: (ctx, i) {
            final item = order.orderItems[i];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                children: [
                  AdminThumbnail(imageUrl: item.bookImageUrl, fallbackIcon: Icons.book_outlined),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: Text(item.bookTitle, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 3, child: Text(item.bookAuthorName, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 1, child: Text('${item.quantity}', style: adminRowStyle)),
                  Expanded(flex: 2, child: Text('${item.price.toStringAsFixed(2)} BAM', style: adminRowStyle)),
                  Expanded(flex: 2, child: Text('${item.subtotal.toStringAsFixed(2)} BAM', style: adminRowStyle)),
                ],
              ),
            );
          },
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'Total: ${order.totalPrice.toStringAsFixed(2)} BAM',
              style: const TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;

  const _Badge(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.mediumBrown).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? AppColors.mediumBrown).withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.darkBrown,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
