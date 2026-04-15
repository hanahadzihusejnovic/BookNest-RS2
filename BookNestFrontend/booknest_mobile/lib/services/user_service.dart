import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
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
    final response = await http.get(
      Uri.parse('$baseUrl/User/current-user'),
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
    String? city,
    String? country,
    String? imageUrl,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/User/update-self'),
      headers: await _headers(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'emailAddress': emailAddress,
        'phoneNumber': phoneNumber,
        'address': address,
        'city': city,
        'country': country,
        'imageUrl': imageUrl,
      }),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update profile');
  }

  Future<void> deleteSelf() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/User/delete-self'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete account');
    }
  }
}