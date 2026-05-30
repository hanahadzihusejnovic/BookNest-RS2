import 'dart:convert';
import '../layouts/constants.dart';
import '../models/category.dart';
import 'http_client.dart';

class CategoryService {
  Future<List<Category>> getCategories() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Category?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Category.fromJson(e)).toList();
    }
    throw Exception('Failed to load categories');
  }

  Future<Category> createCategory(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Category'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create category');
  }

  Future<Category> updateCategory(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Category/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update category');
  }

  Future<void> deleteCategory(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Category/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete category');
    }
  }
}
