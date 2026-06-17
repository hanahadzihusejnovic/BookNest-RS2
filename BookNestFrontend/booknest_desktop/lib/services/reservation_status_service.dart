import 'dart:convert';
import '../layouts/constants.dart';
import '../models/reservation_status.dart';
import 'http_client.dart';

class ReservationStatusService {
  Future<List<ReservationStatus>> getAll() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/ReservationStatus?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => ReservationStatus.fromJson(e)).toList();
    }
    throw Exception('Failed to load reservation statuses');
  }

  Future<ReservationStatus> create(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/ReservationStatus'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReservationStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create reservation status');
  }

  Future<ReservationStatus> update(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/ReservationStatus/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return ReservationStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update reservation status');
  }

  Future<void> delete(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/ReservationStatus/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reservation status');
    }
  }
}
