import 'event.dart';

class EventRecommendation {
  final EventModel event;
  final String reason;

  EventRecommendation({
    required this.event,
    required this.reason,
  });

  factory EventRecommendation.fromJson(Map<String, dynamic> json) {
    return EventRecommendation(
      event: EventModel.fromJson(json['event']),
      reason: json['reason'] ?? '',
    );
  }
}