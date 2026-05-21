import 'dart:convert';
import '../layouts/constants.dart';
import '../models/organizer.dart';
import 'auth_service.dart';
import 'http_client.dart';

class OrganizerService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Organizer>> getOrganizers() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Organizer?RetrieveAll=true'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Organizer.fromJson(e)).toList();
    }
    throw Exception('Failed to load organizers');
  }

  Future<Organizer> getOrganizer(int id) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Organizer/$id'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return Organizer.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load organizer');
  }

  Future<Organizer> createOrganizer({
    required String firstName,
    required String lastName,
    required String contactEmail,
    String? phoneNumber,
  }) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Organizer'),
      headers: await _headers(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'contactEmail': contactEmail,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Organizer.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create organizer');
  }

  Future<Organizer> updateOrganizer(
    int id, {
    required String firstName,
    required String lastName,
    required String contactEmail,
    String? phoneNumber,
  }) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Organizer/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'contactEmail': contactEmail,
        'phoneNumber': phoneNumber,
      }),
    );
    if (response.statusCode == 200) {
      return Organizer.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update organizer');
  }

  Future<void> deleteOrganizer(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Organizer/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete organizer');
    }
  }
}
