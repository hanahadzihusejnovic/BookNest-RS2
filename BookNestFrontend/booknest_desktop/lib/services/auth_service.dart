import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _firstNameKey = 'first_name';
  static const String _lastNameKey = 'last_name';
  static const String _emailKey = 'email';
  static const String _rolesKey = 'roles';

  static const String _rememberMeKey = 'remember_me';
  static const String _savedUsernameKey = 'saved_username';
  static const String _savedPasswordKey = 'saved_password';

  // Login
  Future<LoginResponse> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final response = await _apiService.login(request);
    await _saveUserData(response);
    return response;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedUsername = prefs.getString(_savedUsernameKey);
    final savedPassword = prefs.getString(_savedPasswordKey);

    await prefs.clear();

    if (rememberMe && savedUsername != null && savedPassword != null) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedUsernameKey, savedUsername);
      await prefs.setString(_savedPasswordKey, savedPassword);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    await prefs.setInt(_userIdKey, response.userId);
    await prefs.setString(_usernameKey, response.username);
    await prefs.setString(_firstNameKey, response.firstName);
    await prefs.setString(_lastNameKey, response.lastName);
    await prefs.setString(_emailKey, response.emailAddress);
    await prefs.setStringList(_rolesKey, response.roles);
  }

  // ========== REMEMBER ME ========== //

  Future<void> saveRememberMe(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, true);
    await prefs.setString(_savedUsernameKey, username);
    await prefs.setString(_savedPasswordKey, password);
  }

  Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_savedUsernameKey);
    await prefs.remove(_savedPasswordKey);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (!rememberMe) return null;

    final username = prefs.getString(_savedUsernameKey);
    final password = prefs.getString(_savedPasswordKey);
    if (username == null || password == null) return null;

    return {'username': username, 'password': password};
  }

  // ========== ROLE METODE ========== //

  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_rolesKey) ?? [];
  }

  Future<bool> isAdmin() async {
    final roles = await getRoles();
    return roles.contains('Admin');
  }

}
