import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';

class ApiService {

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/Auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/Auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
      } else {
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Registration failed. Please try again.');
        } catch (jsonError) {
          if (jsonError is Exception) rethrow;
          throw Exception('Registration failed. Please try again.');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint, String token) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response;
  }

  Future<void> forgotPassword(String email) async {
    try {
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/Auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );


      if (response.statusCode != 200) {
        throw Exception('Request failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during forgot password: $e');
    }
  }

  Future<void> resetPassword(String token, String newPassword, String confirmPassword) async {
    try {
      
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/Auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );


      if (response.statusCode != 200) {
        throw Exception('Request failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during reset password: $e');
    }
  }
}