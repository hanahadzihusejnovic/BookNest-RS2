class FavoriteModel {
  final int id;
  final int bookId;
  final String bookTitle;
  final String? bookImageUrl;
  final String? bookAuthor;

  FavoriteModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookImageUrl,
    this.bookAuthor,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'],
      bookId: json['bookId'],
      bookTitle: json['bookTitle'] ?? '',
      bookImageUrl: json['bookImageUrl'],
      bookAuthor: json['bookAuthor'],
    );
  }
}