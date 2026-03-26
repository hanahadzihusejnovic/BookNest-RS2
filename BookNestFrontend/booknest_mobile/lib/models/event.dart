class EventModel {
  final int id;
  final String name;
  final String? description;
  final int eventCategoryId;
  final String eventCategoryName;
  final int organizerId;
  final String organizerName;
  final DateTime eventDate;
  final String eventTime;
  final String eventType;
  final String? address;
  final String? city;
  final String? country;
  final double ticketPrice;
  final int capacity;
  final bool isActive;
  final String? imageUrl;
  final int reservedSeats;

  EventModel({
    required this.id,
    required this.name,
    this.description,
    required this.eventCategoryId,
    required this.eventCategoryName,
    required this.organizerId,
    required this.organizerName,
    required this.eventDate,
    required this.eventTime,
    required this.eventType,
    this.address,
    this.city,
    this.country,
    required this.ticketPrice,
    required this.capacity,
    required this.isActive,
    this.imageUrl,
    required this.reservedSeats,
  });

  int get availableSeats => capacity - reservedSeats;

  String get location {
    if (eventType == 'Online') return 'Online';
    final parts = [address, city, country].where((e) => e != null && e.isNotEmpty).toList();
    return parts.join(', ');
  }

  String get formattedDate {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final day = days[eventDate.weekday - 1];
    final timeParts = eventTime.split(':');
    final hour = timeParts[0];
    final minute = timeParts[1];
    return '$day at $hour:$minute';
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      eventCategoryId: json['eventCategoryId'],
      eventCategoryName: json['eventCategoryName'] ?? '',
      organizerId: json['organizerId'],
      organizerName: json['organizerName'] ?? '',
      eventDate: DateTime.parse(json['eventDate']),
      eventTime: json['eventTime'] ?? '00:00:00',
      eventType: json['eventType'] ?? '',
      address: json['address'],
      city: json['city'],
      country: json['country'],
      ticketPrice: (json['ticketPrice'] as num).toDouble(),
      capacity: json['capacity'],
      isActive: json['isActive'],
      imageUrl: json['imageUrl'],
      reservedSeats: json['reservedSeats'],
    );
  }
}