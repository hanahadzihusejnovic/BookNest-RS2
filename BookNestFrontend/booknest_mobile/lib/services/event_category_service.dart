import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_category.dart';
import 'auth_service.dart';

class EventCategoryService {
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

  Future<List<EventCategory>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/EventCategory?RetrieveAll=true'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => EventCategory.fromJson(e)).toList();
    }
    throw Exception('Failed to load event categories');
  }
}