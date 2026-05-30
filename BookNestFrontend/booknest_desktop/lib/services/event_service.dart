import 'dart:convert';
import 'dart:io';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/event.dart';
import '../models/reservation.dart';
import 'auth_service.dart';
import 'http_client.dart';

class EventService {
  final AuthService _authService = AuthService();

  Future<List<Event>> getEvents({
    int? eventCategoryId,
    int? organizerId,
    int pageSize = 200,
  }) async {
    final params = <String, String>{'PageSize': pageSize.toString()};
    if (eventCategoryId != null) params['EventCategoryId'] = eventCategoryId.toString();
    if (organizerId != null) params['OrganizerId'] = organizerId.toString();

    final uri = Uri.parse('${AppConstants.baseUrl}/Event')
        .replace(queryParameters: params);

    final response = await HttpClient.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Event.fromJson(e)).toList();
    }
    throw Exception('Failed to load events');
  }

  Future<Event> getEvent(int id) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Event/$id'),
    );
    if (response.statusCode == 200) return Event.fromJson(jsonDecode(response.body));
    throw Exception('Failed to load event');
  }

  Future<List<Reservation>> getEventReservations(int eventId) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/EventReservation/event/$eventId');
    final response = await HttpClient.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> items = jsonDecode(response.body);
      return items.map((e) => Reservation.fromJson(e)).toList();
    }
    throw Exception('Failed to load event reservations');
  }

  Future<void> updateEvent(int id, Map<String, dynamic> body) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Event/$id'),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update event');
    }
  }

  Future<void> deleteEvent(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Event/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete event');
    }
  }

  Future<void> createEvent(Map<String, dynamic> body) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Event'),
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
