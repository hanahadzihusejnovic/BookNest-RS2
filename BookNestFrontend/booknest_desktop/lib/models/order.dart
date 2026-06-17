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

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = json['orderItems'] as List<dynamic>? ?? [];
    final itemsCount = items.isNotEmpty
        ? items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 1))
        : (json['itemsCount'] as num?)?.toInt() ?? 0;
    return Order(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      orderDate: DateTime.tryParse(json['orderDate']?.toString() ?? '') ?? DateTime.now(),
      status: json['orderStatusName'] ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      itemCount: itemsCount,
    );
  }
}
