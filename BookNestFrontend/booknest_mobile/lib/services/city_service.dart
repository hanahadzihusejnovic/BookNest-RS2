import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/city.dart';

class CityService {

  Future<List<City>> getCities() async {
    final response = await http.get(
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