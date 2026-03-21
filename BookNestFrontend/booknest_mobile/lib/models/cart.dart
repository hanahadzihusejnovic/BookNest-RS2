class CartModel {
  final int id;
  final int userId;
  final List<CartItemModel> cartItems;

  CartModel({
    required this.id,
    required this.userId,
    required this.cartItems,
  });

  double get totalPrice =>
      cartItems.fold(0, (sum, item) => sum + item.subtotal);
  int get totalItems =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'],
      userId: json['userId'],
      cartItems: (json['cartItems'] as List<dynamic>?)
              ?.map((i) => CartItemModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class CartItemModel {
  final int id;
  final int bookId;
  final String bookTitle;
  final String? bookImageUrl;
  final String? bookAuthor;
  final double price;
  int quantity;

  CartItemModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookImageUrl,
    this.bookAuthor,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      bookId: json['bookId'],
      bookTitle: json['bookTitle'] ?? '',
      bookImageUrl: json['bookImageUrl'],
      bookAuthor: json['bookAuthorName'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
    );
  }
}