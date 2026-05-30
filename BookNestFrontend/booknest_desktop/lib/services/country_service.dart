import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/country.dart';

class CountryService {
  Future<List<Country>> getCountries() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Country?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => Country.fromJson(e)).toList();
    }
    throw Exception('Failed to load countries');
  }

  Future<Country> createCountry(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Country'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Country.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create country');
  }

  Future<Country> updateCountry(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Country/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return Country.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update country');
  }

  Future<void> deleteCountry(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Country/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete country');
    }
  }
}
