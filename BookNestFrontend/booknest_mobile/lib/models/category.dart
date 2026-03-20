class Category {
  final int id;
  final String name;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  static List<Category> getDummyCategories() {
    return [
      Category(id: 1, name: 'Fiction'),
      Category(id: 2, name: 'Romance'),
      Category(id: 3, name: 'Fantasy'),
      Category(id: 4, name: 'Science Fiction'),
      Category(id: 5, name: 'Mystery'),
      Category(id: 6, name: 'Thriller'),
      Category(id: 7, name: 'Horror'),
      Category(id: 8, name: 'Historical Fiction'),
    ];
  }
}