import 'dart:convert';
import '../layouts/constants.dart';
import '../models/author.dart';
import 'auth_service.dart';
import 'http_client.dart';

class AuthorService {
  final AuthService _authService = AuthService();

  Future<List<Author>> getAuthors() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Author'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Author.fromJson(e)).toList();
    }
    throw Exception('Failed to load authors');
  }
}
