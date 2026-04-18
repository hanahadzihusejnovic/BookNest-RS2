import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/reservation.dart';
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
}
