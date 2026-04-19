class OrderDetail {
  final int id;
  final int userId;
  final String userFullName;
  final DateTime orderDate;
  final DateTime? shippedDate;
  final String status;
  final double totalPrice;
  final OrderShipping shipping;
  final OrderPayment payment;
  final List<OrderItem> orderItems;

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

  OrderDetail({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.orderDate,
    this.shippedDate,
    required this.status,
    required this.totalPrice,
    required this.shipping,
    required this.payment,
    required this.orderItems,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      orderDate: DateTime.tryParse(json['orderDate']?.toString() ?? '') ?? DateTime.now(),
      shippedDate: json['shippedDate'] != null
          ? DateTime.tryParse(json['shippedDate'].toString())
          : null,
      status: _parseStatus(json['status']),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      shipping: OrderShipping.fromJson(json['shipping'] as Map<String, dynamic>? ?? {}),
      payment: OrderPayment.fromJson(json['payment'] as Map<String, dynamic>? ?? {}),
      orderItems: (json['orderItems'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderShipping {
  final String address;
  final String city;
  final String country;
  final String postalCode;
  final DateTime? shippedDate;

  OrderShipping({
    required this.address,
    required this.city,
    required this.country,
    required this.postalCode,
    this.shippedDate,
  });

  factory OrderShipping.fromJson(Map<String, dynamic> json) {
    return OrderShipping(
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postalCode'] ?? '',
      shippedDate: json['shippedDate'] != null
          ? DateTime.tryParse(json['shippedDate'].toString())
          : null,
    );
  }
}

class OrderPayment {
  final String paymentMethod;
  final double amount;
  final DateTime paymentDate;
  final bool isSuccessful;
  final String? transactionId;

  static const _methodLabels = {
    0: 'Credit Card',
    1: 'Debit Card',
    2: 'PayPal',
    3: 'Bank Transfer',
    4: 'Cash',
  };

  static String _parseMethod(dynamic raw) {
    final n = int.tryParse(raw?.toString() ?? '');
    if (n != null) return _methodLabels[n] ?? raw.toString();
    return raw?.toString() ?? '';
  }

  OrderPayment({
    required this.paymentMethod,
    required this.amount,
    required this.paymentDate,
    required this.isSuccessful,
    this.transactionId,
  });

  factory OrderPayment.fromJson(Map<String, dynamic> json) {
    return OrderPayment(
      paymentMethod: _parseMethod(json['paymentMethod']),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? '') ?? DateTime.now(),
      isSuccessful: json['isSuccessful'] ?? false,
      transactionId: json['transactionId'],
    );
  }
}

class OrderItem {
  final int id;
  final int bookId;
  final String bookTitle;
  final String bookAuthorName;
  final String? bookImageUrl;
  final int quantity;
  final double price;

  double get subtotal => quantity * price;

  OrderItem({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthorName,
    this.bookImageUrl,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      bookId: json['bookId'] ?? 0,
      bookTitle: json['bookTitle'] ?? '',
      bookAuthorName: json['bookAuthorName'] ?? '',
      bookImageUrl: json['bookImageUrl'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
