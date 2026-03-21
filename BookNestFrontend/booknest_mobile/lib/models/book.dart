class Book {
  final int id;
  final String title;
  final String author;
  final String? imageUrl;
  final String? description;
  final double? price;
  final int? pageCount;
  final String? authorBiography;
  final String? authorImageUrl;
  final double? averageRating;
  final int reviewCount;
  final List<BookReview> reviews;
  final List<String> categories;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.imageUrl,
    this.description,
    this.price,
    this.pageCount,
    this.authorBiography,
    this.authorImageUrl,
    this.averageRating,
    this.reviewCount = 0,
    this.reviews = const [],
    this.categories = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['authorName'] ?? '',
      imageUrl: json['coverImageUrl'],
      description: json['description'],
      price: (json['price'] as num?)?.toDouble(),
      pageCount: json['pageCount'],
      authorBiography: json['authorBiography'],
      authorImageUrl: json['authorImageUrl'],
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => BookReview.fromJson(r))
              .toList() ??
          [],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((c) => c['name'] as String)
              .toList() ??
          [],
    );
  }

  static List<Book> getDummyBooks() {
    return [
      Book(id: 1, title: 'The Outsiders', author: 'S.E. Hinton', price: 12.99),
      Book(id: 2, title: "Alice's Adventures in Wonderland", author: 'Lewis Carroll', price: 10.99),
      Book(id: 3, title: 'Tuesdays with Morrie', author: 'Mitch Albom', price: 11.99),
      Book(id: 4, title: 'To Kill a Mockingbird', author: 'Harper Lee', price: 13.99),
      Book(id: 5, title: '1984', author: 'George Orwell', price: 12.99),
    ];
  }
}

class BookReview {
  final int id;
  final int userId;
  final String userFullName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  BookReview({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory BookReview.fromJson(Map<String, dynamic> json) {
    return BookReview(
      id: json['id'],
      userId: json['userId'],
      userFullName: json['userFullName'] ?? '',
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}