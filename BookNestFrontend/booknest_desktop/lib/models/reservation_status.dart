class ReservationStatus {
  final int id;
  final String name;

  ReservationStatus({required this.id, required this.name});

  factory ReservationStatus.fromJson(Map<String, dynamic> json) {
    return ReservationStatus(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}
