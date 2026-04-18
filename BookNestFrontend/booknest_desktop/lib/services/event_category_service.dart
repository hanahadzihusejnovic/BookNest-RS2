import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/event_category.dart';
import 'auth_service.dart';

class EventCategoryService {
  final AuthService _authService = AuthService();

  Future<List<EventCategory>> getCategories() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/EventCategory?RetrieveAll=true'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => EventCategory.fromJson(e)).toList();
    }
    throw Exception('Failed to load event categories');
  }
}
