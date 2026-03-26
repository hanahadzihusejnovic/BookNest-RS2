import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'auth_service.dart';

class ReviewService {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
  final AuthService _authService = AuthService();

  Future<void> addReview({
    required int bookId,
    required int rating,
    String? comment,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/Review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'bookId': bookId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add review: ${response.body}');
    }
  }

  Future<List<BookReview>> getBookReviews(int bookId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Review/book/$bookId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((r) => BookReview.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<void> updateReview({
  required int reviewId,
  required int rating,
  String? comment,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.put(
      Uri.parse('$baseUrl/Review/$reviewId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update review: ${response.body}');
    }
  }

  Future<void> deleteReview(int reviewId) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.delete(
      Uri.parse('$baseUrl/Review/$reviewId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete review: ${response.body}');
    }
  }

  Future<void> addEventReview({
    required int eventId,
    required int rating,
    String? comment,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/Review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'eventId': eventId,
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add review: ${response.body}');
    }
  }

  Future<List<BookReview>> getEventReviews(int eventId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Review/event/$eventId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((r) => BookReview.fromJson(r)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }
}