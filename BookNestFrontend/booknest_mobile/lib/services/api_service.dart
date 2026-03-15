import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';

class ApiService {
  // ← PROMIJENI OVO NA SVOJU BACKEND ADRESU!
  static const String baseUrl = 'http://10.0.2.2:7110/api';

  // Login metoda
  Future<LoginResponse> login(LoginRequest request) async {
  try {
    print('🔵 API: Sending login request to: $baseUrl/Auth/login');
    print('🔵 API: Username: ${request.username}');
    print('🔵 API: Password length: ${request.password.length}');
    
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    print('🔵 API: Response status: ${response.statusCode}');
    print('🔵 API: Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ API: Login successful!');
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      print('❌ API: Login failed with status ${response.statusCode}');
      throw Exception('Login failed: ${response.body}');
    }
  } catch (e) {
    print('❌ API: Exception caught: $e');
    print('❌ API: Exception type: ${e.runtimeType}');
    throw Exception('Error during login: $e');
  }
}

  // Register metoda
Future<void> register(RegisterRequest request) async {
  try {
    print('🔵 API: Sending register request to: $baseUrl/Auth/register');
    
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    print('🔵 API: Response status: ${response.statusCode}');
    print('🔵 API: Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ API: Registration successful!');
    } else {
      print('❌ API: Registration failed with status ${response.statusCode}');
      throw Exception('Registration failed: ${response.body}');
    }
  } catch (e) {
    print('❌ API: Exception: $e');
    throw Exception('Error during registration: $e');
  }
}

  // GET request sa token-om (za kasnije kad budeš pozivala zaštićene endpoint-e)
  Future<http.Response> get(String endpoint, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // POST request sa token-om
  Future<http.Response> post(String endpoint, Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    return response;
  }

  // Forgot Password
Future<void> forgotPassword(String email) async {
  try {
    print('🔵 API: Sending forgot password request');
    
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    print('🔵 API: Response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Request failed: ${response.body}');
    }
  } catch (e) {
    print('❌ API: Exception: $e');
    throw Exception('Error during forgot password: $e');
  }
}

// Reset Password
Future<void> resetPassword(String token, String newPassword, String confirmPassword) async {
  try {
    print('🔵 API: Sending reset password request');
    
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    print('🔵 API: Response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Request failed: ${response.body}');
    }
  } catch (e) {
    print('❌ API: Exception: $e');
    throw Exception('Error during reset password: $e');
  }
}
}