class PaymentMethod {
  final int id;
  final String name;

  PaymentMethod({required this.id, required this.name});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
