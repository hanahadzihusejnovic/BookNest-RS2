class Author {
  final int id;
  final String firstName;
  final String lastName;

  Author({required this.id, required this.firstName, required this.lastName});

  String get name => '$firstName $lastName'.trim();

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
    );
  }
}
