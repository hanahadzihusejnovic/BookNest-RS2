class EventCategory {
  final int id;
  final String name;
  final String description;

  EventCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}