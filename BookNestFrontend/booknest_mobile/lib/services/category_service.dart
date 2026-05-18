import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/category.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService _authService = AuthService();

  Future<List<Category>> getCategories() async {
    try {
      print('🔵 CATEGORY SERVICE: Fetching categories');
      
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await HttpClient.get(
        Uri.parse('${AppConstants.baseUrl}/Category'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 CATEGORY SERVICE: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['items'] == null) {
          print('⚠️ CATEGORY SERVICE: No items in response');
          return [];
        }
        
        final List<dynamic> data = responseData['items'];
        print('✅ CATEGORY SERVICE: Fetched ${data.length} categories');
        
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.body}');
      }
    } catch (e) {
      print('❌ CATEGORY SERVICE: Error: $e');
      rethrow;
    }
  }
}