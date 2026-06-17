class ReadingStatus {
  final int id;
  final String name;

  ReadingStatus({required this.id, required this.name});

  factory ReadingStatus.fromJson(Map<String, dynamic> json) {
    return ReadingStatus(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
