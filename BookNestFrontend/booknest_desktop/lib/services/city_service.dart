import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/city.dart';
import 'auth_service.dart';

class CityService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<City>> getCities() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/City?RetrieveAll=true'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => City.fromJson(e)).toList();
    }
    throw Exception('Failed to load cities');
  }

  Future<City> createCity(String name, int countryId) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/City'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'countryId': countryId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return City.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create city');
  }

  Future<City> updateCity(int id, String name, int countryId) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/City/$id'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'countryId': countryId}),
    );
    if (response.statusCode == 200) {
      return City.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update city');
  }

  Future<void> deleteCity(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/City/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete city');
    }
  }
}
