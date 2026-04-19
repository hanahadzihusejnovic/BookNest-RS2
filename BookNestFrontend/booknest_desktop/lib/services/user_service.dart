import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/review.dart';
import '../models/reservation.dart';
import '../models/order.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<User>> getUsers({String? search, int pageSize = 50}) async {
    final params = <String, String>{'PageSize': pageSize.toString()};
    if (search != null && search.isNotEmpty) params['Text'] = search;

    final uri = Uri.parse('${AppConstants.baseUrl}/User')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => User.fromJson(e)).toList();
    }
    throw Exception('Failed to load users');
  }

  Future<User> getUser(int id) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/User/$id'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) return User.fromJson(jsonDecode(response.body));
    throw Exception('Failed to load user');
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/User/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/User/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }

  Future<List<Review>> getUserReviews(int userId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/Review')
        .replace(queryParameters: {'PageSize': '500'});
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items
          .map((e) => Review.fromJson(e))
          .where((r) => r.userId == userId)
          .toList();
    }
    throw Exception('Failed to load user reviews');
  }

  Future<List<Reservation>> getUserReservations(int userId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/EventReservation')
        .replace(queryParameters: {'PageSize': '500'});
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items
          .map((e) => Reservation.fromJson(e))
          .where((r) => r.userId == userId)
          .toList();
    }
    throw Exception('Failed to load user reservations');
  }

  Future<void> deleteReview(int reviewId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/Review/$reviewId'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete review');
    }
  }

  Future<List<Order>> getUserOrders(int userId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/Order')
        .replace(queryParameters: {'PageSize': '500'});
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items
          .map((e) => Order.fromJson(e))
          .where((o) => o.userId == userId)
          .toList();
    }
    throw Exception('Failed to load user orders');
  }

}
