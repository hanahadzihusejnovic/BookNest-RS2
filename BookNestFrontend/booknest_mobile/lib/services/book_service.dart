import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/book.dart';
import '../models/book_recommendation.dart';

class BookService {
  Future<List<Book>> getBooks() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Book'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Book.fromJson(json)).toList();
    }
    throw Exception('Failed to load books');
  }

  Future<List<Book>> getFeaturedBooks() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Book?PageSize=5'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['items'] == null) return [];
      final List<dynamic> data = responseData['items'];
      return data.map((json) => Book.fromJson(json)).toList();
    }
    throw Exception('Failed to load books');
  }

  Future<List<Book>> getBooksByCategory(int categoryId, {int pageSize = 10}) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Book?CategoryId=$categoryId&PageSize=$pageSize'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      if (responseData['items'] == null) return [];
      final List<dynamic> data = responseData['items'];
      return data.map((json) => Book.fromJson(json)).toList();
    }
    throw Exception('Failed to load books');
  }

  Future<List<BookRecommendation>> getRecommendedBooks() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Book/recommended?count=6'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BookRecommendation.fromJson(json)).toList();
    }
    throw Exception('Failed to load recommended books');
  }

  Future<List<BookRecommendation>> getContentBasedRecommendations() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Book/recommended-content?count=6'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => BookRecommendation.fromJson(json)).toList();
    }
    throw Exception('Failed to load recommendations');
  }

  Future<Book> getBookById(int id) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Book/$id'),
    );
    if (response.statusCode == 200) {
      return Book.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load book details');
  }
}
