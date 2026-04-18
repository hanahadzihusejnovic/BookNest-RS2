class Event {
  final int id;
  final String name;
  final String? description;
  final int eventCategoryId;
  final String eventCategoryName;
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

  Event({
    required this.id,
    required this.name,
    this.description,
    required this.eventCategoryId,
    required this.eventCategoryName,
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

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      eventCategoryId: json['eventCategoryId'] ?? 0,
      eventCategoryName: json['eventCategoryName'] ?? '',
      organizerName: json['organizerName'] ?? '',
      eventDate: DateTime.tryParse(json['eventDate']?.toString() ?? '') ?? DateTime.now(),
      eventTime: json['eventTime'] ?? '00:00:00',
      eventType: json['eventType'] ?? '',
      address: json['address'],
      city: json['city'],
      country: json['country'],
      ticketPrice: (json['ticketPrice'] as num?)?.toDouble() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] ?? false,
      imageUrl: json['imageUrl'],
      reservedSeats: (json['reservedSeats'] as num?)?.toInt() ?? 0,
    );
  }
}
