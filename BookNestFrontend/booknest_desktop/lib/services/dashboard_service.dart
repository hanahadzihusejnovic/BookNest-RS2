import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DashboardService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Ukupan broj usera
  Future<int> getTotalUsers() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/User?PageSize=1'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load users count');
  }

  // Ukupan broj knjiga
  Future<int> getTotalBooks() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/Book?PageSize=1'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load books count');
  }

  // Broj narudžbi sa statusom Pending
  Future<int> getPendingOrdersCount() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/Order?Status=Pending&PageSize=1'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load orders count');
  }

  // Broj rezervacija sa statusom Pending
  Future<int> getPendingReservationsCount() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/EventReservation?ReservationStatus=0&PageSize=1'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load reservations count');
  }

  // Broj nadolazećih evenata (datum > danas)
  Future<int> getUpcomingEventsCount() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/Event?IsActive=true&PageSize=1000'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      final now = DateTime.now();
      return items
          .where((e) => DateTime.tryParse(e['eventDate'] ?? '')?.isAfter(now) ?? false)
          .length;
    }
    throw Exception('Failed to load events count');
  }

  Future<List<Map<String, dynamic>>> getCategoryStats() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/Dashboard/category-stats'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Failed to load category stats');
  }
}
