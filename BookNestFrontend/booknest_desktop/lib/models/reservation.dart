class Reservation {
  final int id;
  final int userId;
  final String userFullName;
  final String userEmail;
  final int eventId;
  final String eventName;
  final String eventLocation;
  final DateTime eventDateTime;
  final DateTime reservationDate;
  final int quantity;
  final double totalPrice;
  final String reservationStatus;

  Reservation({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.userEmail,
    required this.eventId,
    required this.eventName,
    required this.eventLocation,
    required this.eventDateTime,
    required this.reservationDate,
    required this.quantity,
    required this.totalPrice,
    required this.reservationStatus,
  });

  static const _statusLabels = {
    0: 'Pending',
    1: 'Confirmed',
    2: 'Cancelled',
    3: 'Attended',
  };

  static String _parseStatus(dynamic raw) {
    final n = int.tryParse(raw?.toString() ?? '');
    if (n != null) return _statusLabels[n] ?? raw.toString();
    return raw?.toString() ?? '';
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userFullName: json['userFullName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      eventId: json['eventId'] ?? 0,
      eventName: json['eventName'] ?? '',
      eventLocation: json['eventLocation'] ?? '',
      eventDateTime: DateTime.tryParse(json['eventDateTime']?.toString() ?? '') ?? DateTime.now(),
      reservationDate: DateTime.tryParse(json['reservationDate']?.toString() ?? '') ?? DateTime.now(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      reservationStatus: _parseStatus(json['reservationStatus']),
    );
  }
}
