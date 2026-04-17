import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  Future<List<Category>> getCategories() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
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
