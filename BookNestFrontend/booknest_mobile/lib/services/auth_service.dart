import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import 'api_service.dart';
import '../models/register_request.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Ključevi za čuvanje u SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _firstNameKey = 'first_name';
  static const String _lastNameKey = 'last_name';
  static const String _emailKey = 'email';

  // Login
  Future<LoginResponse> login(String username, String password) async {
    final request = LoginRequest(username: username, password: password);
    final response = await _apiService.login(request);

    // Sačuvaj token i user info
    await _saveUserData(response);

    return response;
  }

  // Register
  Future<void> register(RegisterRequest request) async {
  await _apiService.register(request);
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Obriši sve podatke
  }

  // Provjeri da li je korisnik ulogovan
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Dobij token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Dobij User ID
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Dobij username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Dobij user info
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
      'token': token,
    };
  }

  // Privatna metoda - sačuva user podatke u SharedPreferences
  Future<void> _saveUserData(LoginResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, response.token);
    await prefs.setInt(_userIdKey, response.userId);
    await prefs.setString(_usernameKey, response.username);
    await prefs.setString(_firstNameKey, response.firstName);
    await prefs.setString(_lastNameKey, response.lastName);
    await prefs.setString(_emailKey, response.emailAddress);
  }
}