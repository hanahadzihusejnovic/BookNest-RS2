class Book {
  final int id;
  final String title;
  final String author;
  final String? imageUrl;
  final String? description;
  final double? price;
  final int? pageCount;
  final List<String> categories;
  final int? stock;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.imageUrl,
    this.description,
    this.price,
    this.pageCount,
    this.categories = const [],
    this.stock,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'] ?? '',
      author: json['authorName'] ?? '',
      imageUrl: (json['coverImageUrl'] as String?)?.trim().isEmpty == true
          ? null
          : json['coverImageUrl'],
      description: json['description'],
      price: (json['price'] as num?)?.toDouble(),
      pageCount: json['pageCount'],
      categories: (json['categories'] as List<dynamic>?)
              ?.map((c) => c['name'] as String)
              .toList() ??
          [],
      stock: json['stock'],
    );
  }
}
