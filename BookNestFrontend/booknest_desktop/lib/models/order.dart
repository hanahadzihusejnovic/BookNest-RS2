class Order {
  final int id;
  final int userId;
  final String userFullName;
  final DateTime orderDate;
  final String status;
  final double totalPrice;
  final int itemCount;

  Order({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.orderDate,
    required this.status,
    required this.totalPrice,
    required this.itemCount,
  });

  static const _statusLabels = {
    0: 'Pending',
    1: 'Processing',
    2: 'Shipped',
    3: 'Delivered',
    4: 'Cancelled',
  };

  static String _parseStatus(dynamic raw) {
    final n = int.tryParse(raw?.toString() ?? '');
    if (n != null) return _statusLabels[n] ?? raw.toString();
    return raw?.toString() ?? '';
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = json['orderItems'] as List<dynamic>? ?? [];
    final itemsCount = (json['itemsCount'] as num?)?.toInt() ?? items.length;
    return Order(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      orderDate: DateTime.tryParse(json['orderDate']?.toString() ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status']),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      itemCount: itemsCount,
    );
  }
}
