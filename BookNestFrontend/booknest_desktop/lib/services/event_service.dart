import 'dart:convert';
import 'dart:io';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import 'auth_service.dart';

class EventService {
  final AuthService _authService = AuthService();

  Future<List<Event>> getEvents({
    int? eventCategoryId,
    int pageSize = 200,
  }) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final params = <String, String>{'PageSize': pageSize.toString()};
    if (eventCategoryId != null) {
      params['EventCategoryId'] = eventCategoryId.toString();
    }

    final uri = Uri.parse('${AppConstants.baseUrl}/Event')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Event.fromJson(e)).toList();
    }
    throw Exception('Failed to load events');
  }

  Future<void> createEvent(Map<String, dynamic> body) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/Event'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create event');
    }
  }

  Future<String> uploadImage(File imageFile, {String? category}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.baseUrl}/Event/upload-image')
        .replace(queryParameters: category != null ? {'category': category} : null);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      final data = jsonDecode(body);
      return data['url'] ?? data.toString();
    }
    throw Exception('Failed to upload image');
  }
}
