class OrderStatus {
  final int id;
  final String name;

  OrderStatus({required this.id, required this.name});

  factory OrderStatus.fromJson(Map<String, dynamic> json) {
    return OrderStatus(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
