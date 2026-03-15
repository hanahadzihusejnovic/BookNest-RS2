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
  static const String _rolesKey = 'roles'; // ← DODANO
  
  // Remember Me ključevi
  static const String _rememberMeKey = 'remember_me';
  static const String _savedUsernameKey = 'saved_username';
  static const String _savedPasswordKey = 'saved_password';

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
    
    // Sačuvaj Remember Me podatke prije brisanja
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final savedUsername = prefs.getString(_savedUsernameKey);
    final savedPassword = prefs.getString(_savedPasswordKey);
    
    await prefs.clear(); // Obriši sve podatke
    
    // Vrati Remember Me podatke ako su bili sačuvani
    if (rememberMe && savedUsername != null && savedPassword != null) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedUsernameKey, savedUsername);
      await prefs.setString(_savedPasswordKey, savedPassword);
    }
    
    print('✅ LOGOUT: User data cleared (including roles)');
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
      'roles': prefs.getStringList(_rolesKey),
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
    
    // ← SAČUVAJ ROLES:
    await prefs.setStringList(_rolesKey, response.roles);
    
    print('✅ AUTH SERVICE: Saved user data with roles: ${response.roles}');
  }

  // ========== REMEMBER ME METODE ========== //

  /// Sačuvaj Remember Me podatke (username i password)
  Future<void> saveRememberMe(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, true);
    await prefs.setString(_savedUsernameKey, username);
    await prefs.setString(_savedPasswordKey, password);
    print('✅ Remember Me: Credentials saved');
  }

  /// Obriši Remember Me podatke
  Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, false);
    await prefs.remove(_savedUsernameKey);
    await prefs.remove(_savedPasswordKey);
    print('✅ Remember Me: Credentials cleared');
  }

  /// Provjeri da li je Remember Me enabled
  Future<bool> isRememberMeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Dobij sačuvane credentials (username i password)
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (!rememberMe) return null;

    final username = prefs.getString(_savedUsernameKey);
    final password = prefs.getString(_savedPasswordKey);

    if (username == null || password == null) return null;

    print('✅ Remember Me: Credentials loaded (username: $username)');
    return {
      'username': username,
      'password': password,
    };
  }

  // ========== ROLE METODE ========== //

  /// Dobij roles trenutnog user-a
  Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_rolesKey) ?? [];
  }

  /// Provjeri da li user ima određenu rolu
  Future<bool> hasRole(String roleName) async {
    final roles = await getRoles();
    return roles.contains(roleName);
  }

  /// Provjeri da li je user Admin
  Future<bool> isAdmin() async {
    return await hasRole('Admin');
  }

  /// Provjeri da li je user obični User
  Future<bool> isUser() async {
    return await hasRole('User');
  }

  // Forgot Password
Future<void> forgotPassword(String email) async {
  await _apiService.forgotPassword(email);
}

// Reset Password
Future<void> resetPassword(String token, String newPassword, String confirmPassword) async {
  await _apiService.resetPassword(token, newPassword, confirmPassword);
}
}