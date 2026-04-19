class Review {
  final int id;
  final int userId;
  final String userFullName;
  final int? bookId;
  final String? bookTitle;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userFullName,
    this.bookId,
    this.bookTitle,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      bookId: json['bookId'],
      bookTitle: json['bookTitle'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
