import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/reservation.dart';
import '../models/reservation_detail.dart';
import 'auth_service.dart';

class ReservationService {
  final AuthService _authService = AuthService();

  Future<List<Reservation>> getReservations({int pageSize = 200}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.baseUrl}/EventReservation')
        .replace(queryParameters: {'PageSize': pageSize.toString()});

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Reservation.fromJson(e)).toList();
    }
    throw Exception('Failed to load reservations');
  }

  Future<ReservationDetail> getReservation(int id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return ReservationDetail.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load reservation');
  }

  Future<void> updateStatus(int id, int status) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'reservationStatus': status}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update reservation status: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> sendReminder(int id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/$id/send-reminder'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send reminder: ${response.statusCode}');
    }
  }
}
