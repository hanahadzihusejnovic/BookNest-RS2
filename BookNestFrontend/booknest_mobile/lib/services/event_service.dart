import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import 'auth_service.dart';

class EventService {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<EventModel>> getEvents({
    String? text,
    int? eventCategoryId,
    bool? isActive,
    int pageSize = 20,
  }) async {
    final params = <String, String>{
      'PageSize': pageSize.toString(),
    };
    if (text != null && text.isNotEmpty) params['Text'] = text;
    if (eventCategoryId != null) params['EventCategoryId'] = eventCategoryId.toString();
    if (isActive != null) params['IsActive'] = isActive.toString();

    final uri = Uri.parse('$baseUrl/Event').replace(queryParameters: params);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => EventModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load events');
  }

  Future<List<EventModel>> getUpcomingEvents({int count = 3}) async {
    final events = await getEvents(isActive: true, pageSize: 50);
    final now = DateTime.now();
    return events
        .where((e) => e.eventDate.isAfter(now))
        .take(count)
        .toList();
  }

  Future<List<EventModel>> getRecommendedEvents({int count = 6}) async {
    final uri = Uri.parse('$baseUrl/Event/recommended?count=$count');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load recommended events');
  }

  Future<List<EventModel>> getContentBasedRecommendations({int count = 6}) async {
    final uri = Uri.parse('$baseUrl/Event/recommended-content?count=$count');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => EventModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load content based event recommendations');
  }
}