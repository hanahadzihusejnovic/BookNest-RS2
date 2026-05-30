import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/favorite.dart';

class FavoriteService {
  Future<bool> isBookInFavorites(int bookId) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Favorite/check/$bookId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    }
    return false;
  }

  Future<void> addToFavorites(int bookId) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Favorite/add'),
      body: jsonEncode({'bookId': bookId}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to add to favorites');
    }
  }

  Future<List<FavoriteModel>> getMyFavorites() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Favorite/my-favorites'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => FavoriteModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load favorites');
  }

  Future<void> removeFromFavoritesById(int bookId) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Favorite/remove/$bookId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from favorites');
    }
  }
}
