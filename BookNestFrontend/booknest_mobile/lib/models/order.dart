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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderDate: DateTime.parse(json['orderDate']),
      status: json['status']?.toString() ?? '',
      totalPrice: (json['totalPrice'] as num).toDouble(),
      orderItems: (json['orderItems'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}