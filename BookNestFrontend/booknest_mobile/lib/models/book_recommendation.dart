import 'book.dart';

class BookRecommendation {
  final Book book;
  final String reason;

  BookRecommendation({
    required this.book,
    required this.reason,
  });

  factory BookRecommendation.fromJson(Map<String, dynamic> json) {
    return BookRecommendation(
      book: Book.fromJson(json['book']),
      reason: json['reason'] ?? '',
    );
  }
}