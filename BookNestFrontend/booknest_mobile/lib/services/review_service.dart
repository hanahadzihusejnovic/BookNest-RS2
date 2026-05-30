import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/book.dart';

class ReviewService {
  Future<void> addReview({
    required int bookId,
    required int rating,
    String? comment,
  }) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Review'),
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
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Review/book/$bookId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((r) => BookReview.fromJson(r)).toList();
    }
    throw Exception('Failed to load reviews');
  }

  Future<void> updateReview({
    required int reviewId,
    required int rating,
    String? comment,
  }) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Review/$reviewId'),
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
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Review/$reviewId'),
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
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Review'),
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
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Review/event/$eventId'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((r) => BookReview.fromJson(r)).toList();
    }
    throw Exception('Failed to load reviews');
  }
}
