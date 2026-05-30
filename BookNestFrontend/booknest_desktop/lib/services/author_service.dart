import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../layouts/constants.dart';
import '../models/author.dart';
import 'auth_service.dart';
import 'http_client.dart';

class AuthorService {
  final AuthService _authService = AuthService();

  Future<List<Author>> getAuthors() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Author?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Author.fromJson(e)).toList();
    }
    throw Exception('Failed to load authors');
  }

  Future<Author> getAuthor(int id) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Author/$id'),
    );
    if (response.statusCode == 200) {
      return Author.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load author');
  }

  Future<String> uploadImage(File imageFile) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.baseUrl}/Author/upload-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final data = jsonDecode(body);
      return data['imageUrl'] as String;
    }
    throw Exception('Failed to upload image');
  }

  Future<Author> createAuthor({
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    DateTime? dateOfDeath,
    required String biography,
    String? imageUrl,
  }) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Author'),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        if (dateOfDeath != null) 'dateOfDeath': dateOfDeath.toIso8601String(),
        'biography': biography,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Author.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create author');
  }

  Future<Author> updateAuthor(int id, {
    required String firstName,
    required String lastName,
    required DateTime dateOfBirth,
    DateTime? dateOfDeath,
    required String biography,
    String? imageUrl,
  }) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Author/$id'),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        if (dateOfDeath != null) 'dateOfDeath': dateOfDeath.toIso8601String(),
        'biography': biography,
        'imageUrl': imageUrl,
      }),
    );
    if (response.statusCode == 200) {
      return Author.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update author');
  }

  Future<void> deleteAuthor(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Author/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete author');
    }
  }
}
