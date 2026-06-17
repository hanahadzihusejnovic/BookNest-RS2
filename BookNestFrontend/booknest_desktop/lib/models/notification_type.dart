class NotificationType {
  final int id;
  final String name;

  NotificationType({required this.id, required this.name});

  factory NotificationType.fromJson(Map<String, dynamic> json) {
    return NotificationType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
