import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import 'auth_service.dart';
import '../models/favorite.dart';

class FavoriteService {
  final AuthService _authService = AuthService();

  Future<bool> isBookInFavorites(int bookId) async {
    final token = await _authService.getToken();
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Favorite/check/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    }
    return false;
  }

  Future<void> addToFavorites(int bookId) async {
    final token = await _authService.getToken();
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Favorite/add'),
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

  Future<List<FavoriteModel>> getMyFavorites() async {
    final token = await _authService.getToken();
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Favorite/my-favorites'),
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
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Favorite/remove/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from favorites');
    }
  }
}