class OrderItemModel {
  final int id;
  final int bookId;
  final String bookTitle;
  final String? bookAuthorName;
  final String? bookImageUrl;
  final int quantity;
  final double price;
  final double subtotal;

  OrderItemModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookAuthorName,
    this.bookImageUrl,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      bookId: json['bookId'],
      bookTitle: json['bookTitle'] ?? '',
      bookAuthorName: json['bookAuthorName'],
      bookImageUrl: json['bookImageUrl'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class OrderModel {
  final int id;
  final DateTime orderDate;
  final String status;
  final double totalPrice;
  final List<OrderItemModel> orderItems;

  OrderModel({
    required this.id,
    required this.orderDate,
    required this.status,
    required this.totalPrice,
    required this.orderItems,
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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderDate: DateTime.parse(json['orderDate']),
      status: _parseStatus(json['status']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      orderItems: (json['orderItems'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}