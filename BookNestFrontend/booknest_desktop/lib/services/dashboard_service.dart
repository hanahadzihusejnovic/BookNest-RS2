import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';

class DashboardService {
  Future<int> getTotalUsers() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/User?PageSize=1'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load users count');
  }

  Future<int> getTotalBooks() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Book?PageSize=1'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load books count');
  }

  Future<int> getPendingOrdersCount() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Order?Status=Pending&PageSize=1'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load orders count');
  }

  Future<int> getPendingReservationsCount() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/EventReservation?ReservationStatus=0&PageSize=1'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['totalCount'] ?? 0;
    }
    throw Exception('Failed to load reservations count');
  }

  Future<int> getUpcomingEventsCount() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Event?IsActive=true&PageSize=1000'),
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
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Dashboard/category-stats'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Failed to load category stats');
  }
}
