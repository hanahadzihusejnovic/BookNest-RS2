import 'review.dart';

class Book {
  final int id;
  final int authorId;
  final String title;
  final String author;
  final String? authorBiography;
  final String? authorImageUrl;
  final String? imageUrl;
  final String? description;
  final double? price;
  final int? pageCount;
  final List<String> categories;
  final List<int> categoryIds;
  final int? stock;
  final DateTime? publicationDate;
  final double? averageRating;
  final int reviewCount;
  final List<Review> reviews;

  Book({
    required this.id,
    required this.authorId,
    required this.title,
    required this.author,
    this.authorBiography,
    this.authorImageUrl,
    this.imageUrl,
    this.description,
    this.price,
    this.pageCount,
    this.categories = const [],
    this.categoryIds = const [],
    this.stock,
    this.publicationDate,
    this.averageRating,
    this.reviewCount = 0,
    this.reviews = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final cats = json['categories'] as List<dynamic>? ?? [];
    return Book(
      id: json['id'],
      authorId: json['authorId'] ?? 0,
      title: json['title'] ?? '',
      author: json['authorName'] ?? '',
      authorBiography: json['authorBiography'],
      authorImageUrl: json['authorImageUrl'],
      imageUrl: (json['coverImageUrl'] as String?)?.trim().isEmpty == true
          ? null
          : json['coverImageUrl'],
      description: json['description'],
      price: (json['price'] as num?)?.toDouble(),
      pageCount: json['pageCount'],
      categories: cats.map((c) => c['name'] as String).toList(),
      categoryIds: cats.map((c) => c['id'] as int).toList(),
      stock: json['stock'],
      publicationDate: DateTime.tryParse(json['publicationDate'] ?? ''),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((r) => Review.fromJson(r))
              .toList() ??
          [],
    );
  }
}
