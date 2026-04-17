import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'auth_service.dart';

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

  Future<List<User>> getUsers({String? search, int pageSize = 50}) async {
    final params = <String, String>{'PageSize': pageSize.toString()};
    if (search != null && search.isNotEmpty) params['Text'] = search;

    final uri = Uri.parse('${AppConstants.baseUrl}/User')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => User.fromJson(e)).toList();
    }
    throw Exception('Failed to load users');
  }

}
