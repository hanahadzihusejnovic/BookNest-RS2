import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/category.dart';

class CategoryService {
  Future<List<Category>> getCategories() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Category'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['items'] == null) return [];
      final List<dynamic> data = responseData['items'];
      return data.map((json) => Category.fromJson(json)).toList();
    }
    throw Exception('Failed to load categories: ${response.body}');
  }
}
