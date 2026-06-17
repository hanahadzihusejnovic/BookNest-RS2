import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import 'api_service.dart';
import '../models/register_request.dart';
import 'package:http/http.dart' as http;
import '../layouts/constants.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _firstNameKey = 'first_name';
  static const String _lastNameKey = 'last_name';
  static const String _emailKey = 'email';
  static const String _rolesKey = 'roles';
  static const String _expiresAtKey = 'expires_at';

  static const String _rememberMeKey = 'remember_me';
  static const String _savedUsernameKey = 'saved_username';

  Future<LoginResponse> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final response = await _apiService.login(request);
    await _saveUserData(response);
    return response;
  }

  Future<void> register(RegisterRequest request) async {
    await _apiService.register(request);
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/Auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (_) {
      // logout proceeds regardless of server response
    }

    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedUsername = prefs.getString(_savedUsernameKey);

    await _secureStorage.delete(key: _tokenKey);
    await prefs.clear();

    if (rememberMe && savedUsername != null) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedUsernameKey, savedUsername);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final expiresAtStr = prefs.getString(_expiresAtKey);
    if (expiresAtStr != null) {
      final expiresAt = DateTime.parse(expiresAtStr);
      if (DateTime.now().isAfter(expiresAt)) {
        final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
        final savedUsername = prefs.getString(_savedUsernameKey);

        await _secureStorage.delete(key: _tokenKey);
        await prefs.clear();

        if (rememberMe && savedUsername != null) {
          await prefs.setBool(_rememberMeKey, true);
          await prefs.setString(_savedUsernameKey, savedUsername);
        }

        return false;
      }
    }

    return true;
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token == null) return null;

    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getInt(_userIdKey),
      'username': prefs.getString(_usernameKey),
      'firstName': prefs.getString(_firstNameKey),
      'lastName': prefs.getString(_lastNameKey),
      'email': prefs.getString(_emailKey),
      'roles': prefs.getStringList(_rolesKey),
      'token': token,
    };
  }

  Future<void> _saveUserData(LoginResponse response) async {
    await _secureStorage.write(key: _tokenKey, value: response.token);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, response.userId);
    await prefs.setString(_usernameKey, response.username);
    await prefs.setString(_firstNameKey, response.firstName);
    await prefs.setString(_lastNameKey, response.lastName);
    await prefs.setString(_emailKey, response.emailAddress);
    await prefs.setStringList(_rolesKey, response.roles);
    await prefs.setString(_expiresAtKey, response.expiresAt.toIso8601String());
  }

  Future<void> saveRememberMe(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, true);
    await prefs.setString(_savedUsernameKey, username);
  }

  Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_savedUsernameKey);
  }

  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<String?> getSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (!rememberMe) return null;
    return prefs.getString(_savedUsernameKey);
  }

  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_rolesKey) ?? [];
  }

  Future<bool> hasRole(String roleName) async {
    final roles = await getRoles();
    return roles.contains(roleName);
  }

  Future<bool> isAdmin() async => await hasRole('Admin');
  Future<bool> isUser() async => await hasRole('User');

  Future<void> forgotPassword(String email) async {
    await _apiService.forgotPassword(email);
  }

  Future<void> resetPassword(String token, String newPassword, String confirmPassword) async {
    await _apiService.resetPassword(token, newPassword, confirmPassword);
  }
}
