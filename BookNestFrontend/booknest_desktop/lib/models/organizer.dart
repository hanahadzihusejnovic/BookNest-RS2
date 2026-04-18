class Organizer {
  final int id;
  final String firstName;
  final String lastName;

  Organizer({required this.id, required this.firstName, required this.lastName});

  String get name => '$firstName $lastName'.trim();

  factory Organizer.fromJson(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
    );
  }
}
