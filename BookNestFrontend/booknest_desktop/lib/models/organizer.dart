import 'event.dart';

class Organizer {
  final int id;
  final String firstName;
  final String lastName;
  final String contactEmail;
  final String? phoneNumber;
  final List<Event> events;

  Organizer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.contactEmail,
    this.phoneNumber,
    this.events = const [],
  });

  String get name => '$firstName $lastName'.trim();
  int get eventCount => events.length;

  factory Organizer.fromJson(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      phoneNumber: json['phoneNumber'],
      events: (json['events'] as List<dynamic>? ?? [])
          .map((e) => Event.fromJson(e))
          .toList(),
    );
  }
}
