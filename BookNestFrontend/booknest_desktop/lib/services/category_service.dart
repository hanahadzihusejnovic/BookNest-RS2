import 'dart:convert';
import '../layouts/constants.dart';
import '../models/category.dart';
import 'auth_service.dart';
import 'http_client.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  Future<List<Category>> getCategories() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Category'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories');
  }
}
