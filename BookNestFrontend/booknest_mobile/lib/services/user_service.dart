import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import 'http_client.dart';
import '../models/user.dart';
import 'auth_service.dart';
import 'dart:io';

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

  Future<User> getCurrentUser() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/User/current-user'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load user');
  }

  Future<User> updateSelf({
    required String firstName,
    required String lastName,
    required String username,
    required String emailAddress,
    String? phoneNumber,
    String? address,
    int? cityId,
    int? countryId,
    String? imageUrl,
  }) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/User/update-self'),
      headers: await _headers(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'emailAddress': emailAddress,
        'phoneNumber': phoneNumber,
        'address': address,
        'cityId': cityId,
        'countryId': countryId,
        'imageUrl': imageUrl,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    try {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to update profile.');
    } catch (jsonError) {
      if (jsonError is Exception) rethrow;
      throw Exception('Failed to update profile.');
    }
  }

  Future<void> deleteSelf() async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/User/delete-self'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete account');
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.baseUrl}/User/upload-image');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imageUrl'] as String;
    }
    throw Exception('Failed to upload image');
  }
}