import 'dart:convert';
import '../layouts/constants.dart';
import '../models/event_type.dart';
import 'http_client.dart';

class EventTypeService {
  Future<List<EventType>> getAll() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/EventType?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => EventType.fromJson(e)).toList();
    }
    throw Exception('Failed to load event types');
  }

  Future<EventType> create(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/EventType'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return EventType.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create event type');
  }

  Future<EventType> update(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/EventType/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return EventType.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update event type');
  }

  Future<void> delete(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/EventType/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete event type');
    }
  }
}
