import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/country.dart';

class CountryService {

  Future<List<Country>> getCountries() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Country?RetrieveAll=true'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => Country.fromJson(e)).toList();
    }
    throw Exception('Failed to load countries');
  }
}