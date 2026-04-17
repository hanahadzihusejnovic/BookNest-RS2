import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/author.dart';
import 'auth_service.dart';

class AuthorService {
  final AuthService _authService = AuthService();

  Future<List<Author>> getAuthors() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
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
