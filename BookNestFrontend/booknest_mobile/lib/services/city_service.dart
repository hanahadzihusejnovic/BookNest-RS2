import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/city.dart';

class CityService {

  Future<List<City>> getCities() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/City?RetrieveAll=true'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => City.fromJson(e)).toList();
    }
    throw Exception('Failed to load cities');
  }
}