import 'book.dart';

class Author {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final DateTime? dateOfDeath;
  final String biography;
  final String? imageUrl;
  final List<Book> books;

  Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.dateOfDeath,
    required this.biography,
    this.imageUrl,
    this.books = const [],
  });

  String get name => '$firstName $lastName'.trim();
  int get bookCount => books.length;

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] ?? '') ?? DateTime(1970),
      dateOfDeath: json['dateOfDeath'] != null
          ? DateTime.tryParse(json['dateOfDeath'])
          : null,
      biography: json['biography'] ?? '',
      imageUrl: json['imageUrl'],
      books: (json['books'] as List<dynamic>? ?? [])
          .map((e) => Book.fromJson(e))
          .toList(),
    );
  }
}
