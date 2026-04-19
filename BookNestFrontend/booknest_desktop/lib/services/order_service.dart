import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import 'auth_service.dart';

class OrderService {
  final AuthService _authService = AuthService();

  Future<List<Order>> getOrders({int pageSize = 200}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.baseUrl}/Order')
        .replace(queryParameters: {'PageSize': pageSize.toString()});

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception('Failed to load orders');
  }

  Future<void> updateStatus(int id, int status) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final body = <String, dynamic>{'status': status};
    if (status == 2) body['shippedDate'] = DateTime.now().toIso8601String();
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/Order/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update order status: ${response.statusCode} ${response.body}');
    }
  }
}
