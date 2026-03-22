class TBRItemModel {
  final int id;
  final int bookId;
  final String bookTitle;
  final String? bookImageUrl;
  final String? bookAuthor;
  final int readingStatus;

  TBRItemModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    this.bookImageUrl,
    this.bookAuthor,
    required this.readingStatus,
  });

  factory TBRItemModel.fromJson(Map<String, dynamic> json) {
    return TBRItemModel(
      id: json['id'],
      bookId: json['bookId'],
      bookTitle: json['bookTitle'] ?? '',
      bookImageUrl: json['bookImageUrl'],
      bookAuthor: json['bookAuthor'],
      readingStatus: json['readingStatus'] ?? 0,
    );
  }
}