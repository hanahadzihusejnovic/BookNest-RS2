import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'auth_service.dart';

class BookService {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
  final AuthService _authService = AuthService();

  Future<List<Book>> getBooks() async {
    try {
      print('🔵 BOOK SERVICE: Fetching books from: $baseUrl/Book');
      
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/Book'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 BOOK SERVICE: Response status: ${response.statusCode}');
      print('🔵 BOOK SERVICE: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ BOOK SERVICE: Fetched ${data.length} books');
        
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books: ${response.body}');
      }
    } catch (e) {
      print('❌ BOOK SERVICE: Error: $e');
      rethrow;
    }
  }

  Future<List<Book>> getFeaturedBooks() async {
    try {
      print('🔵 BOOK SERVICE: Fetching books');
      
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/Book?PageSize=5'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 BOOK SERVICE: Response status: ${response.statusCode}');
      print('🔵 BOOK SERVICE: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // ← PROMJENA: Provjeri da li 'items' postoji i nije null
        if (responseData['items'] == null) {
          print('⚠️ BOOK SERVICE: No items in response');
          return [];
        }
        
        final List<dynamic> data = responseData['items']; // ← Uzmi 'items' umjesto 'result'
        print('✅ BOOK SERVICE: Fetched ${data.length} books');
        
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books: ${response.body}');
      }
    } catch (e) {
      print('❌ BOOK SERVICE: Error: $e');
      rethrow;
    }
  }

  Future<List<Book>> getBooksByCategory(int categoryId, {int pageSize = 10}) async {
    try {
      print('🔵 BOOK SERVICE: Fetching books for category $categoryId');
      
      final token = await _authService.getToken();
      
      if (token == null) {
        throw Exception('No authentication token found');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/Book?CategoryId=$categoryId&PageSize=$pageSize'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 BOOK SERVICE: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['items'] == null) {
          print('⚠️ BOOK SERVICE: No items in response');
          return [];
        }
        
        final List<dynamic> data = responseData['items'];
        print('✅ BOOK SERVICE: Fetched ${data.length} books');
        
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load books: ${response.body}');
      }
    } catch (e) {
      print('❌ BOOK SERVICE: Error: $e');
      rethrow;
    }
  }

  Future<List<Book>> getRecommendedBooks() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/Book/recommended?count=6'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommended books');
      }
    } catch (e) {
      print('❌ BOOK SERVICE: Error: $e');
      rethrow;
    }
  }

  Future<List<Book>> getContentBasedRecommendations() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('$baseUrl/Book/recommended-content?count=6'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      print('❌ BOOK SERVICE: Error: $e');
      rethrow;
    }
  }
}