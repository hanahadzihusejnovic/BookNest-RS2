class City {
  final int id;
  final String name;
  final int countryId;
  final String countryName;

  City({
    required this.id,
    required this.name,
    required this.countryId,
    required this.countryName,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'] ?? '',
      countryId: json['countryId'] ?? 0,
      countryName: json['countryName'] ?? '',
    );
  }
}