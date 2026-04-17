import 'dart:convert';
import 'dart:io';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/book.dart';
import 'auth_service.dart';

class BookService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Book>> getBooks({int pageSize = 200}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/Book')
        .replace(queryParameters: {'PageSize': pageSize.toString()});

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Book.fromJson(e)).toList();
    }
    throw Exception('Failed to load books');
  }

  Future<void> createBook(Map<String, dynamic> request) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/Book'),
      headers: await _headers(),
      body: jsonEncode(request),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create book: ${response.body}');
    }
  }

  Future<String> uploadCover(File imageFile, {String? category}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.baseUrl}/Book/upload-cover')
        .replace(queryParameters: category != null ? {'category': category} : null);

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imageUrl'] ?? data['url'] ?? '';
    }
    throw Exception('Failed to upload cover: ${response.body}');
  }
}
