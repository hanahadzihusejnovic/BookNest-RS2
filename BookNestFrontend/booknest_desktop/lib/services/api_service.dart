import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/login_request.dart';
import '../models/login_response.dart';

class ApiService {

  // Login
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

  // GET request
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

  // POST request
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

  // PUT request
  Future<http.Response> put(String endpoint, Map<String, dynamic> data, String token) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response;
  }

  // DELETE request
  Future<http.Response> delete(String endpoint, String token) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // Forgot Password
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

  // Reset Password
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
