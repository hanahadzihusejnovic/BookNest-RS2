import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/favorite.dart';

class FavoriteService {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
  final AuthService _authService = AuthService();

  Future<bool> isBookInFavorites(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/Favorite/check/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    }
    return false;
  }

  Future<void> addToFavorites(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/Favorite/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bookId': bookId}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to add to favorites');
    }
  }

  Future<void> removeFromFavorites(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/Favorite/remove/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from favorites');
    }
  }

  Future<List<FavoriteModel>> getMyFavorites() async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/Favorite/my-favorites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => FavoriteModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load favorites');
  }

  Future<void> removeFromFavoritesById(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/Favorite/remove/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from favorites');
    }
  }
}