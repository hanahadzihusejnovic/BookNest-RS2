import 'dart:convert';
import '../layouts/constants.dart';
import '../models/event_category.dart';
import 'auth_service.dart';
import 'http_client.dart';

class EventCategoryService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<EventCategory>> getCategories() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/EventCategory?RetrieveAll=true'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => EventCategory.fromJson(e)).toList();
    }
    throw Exception('Failed to load event categories');
  }

  Future<EventCategory> createCategory(String name, String description) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/EventCategory'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return EventCategory.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create event category');
  }

  Future<EventCategory> updateCategory(
      int id, String name, String description) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/EventCategory/$id'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'description': description}),
    );
    if (response.statusCode == 200) {
      return EventCategory.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update event category');
  }

  Future<void> deleteCategory(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/EventCategory/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete event category');
    }
  }
}
