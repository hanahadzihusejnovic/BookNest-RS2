import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import 'auth_service.dart';

class CategoryService {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
  final AuthService _authService = AuthService();

  // Dobavi sve kategorije
  Future<List<Category>> getCategories() async {
    try {
      print('🔵 CATEGORY SERVICE: Fetching categories');
      
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/Category'),
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