import 'dart:convert';
import '../layouts/constants.dart';
import '../models/order.dart';
import '../models/order_detail.dart';
import 'auth_service.dart';
import 'http_client.dart';

class OrderService {
  final AuthService _authService = AuthService();

  Future<List<Order>> getOrders({int pageSize = 200}) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('${AppConstants.baseUrl}/Order')
        .replace(queryParameters: {'PageSize': pageSize.toString()});

    final response = await HttpClient.get(uri, headers: {
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

  Future<OrderDetail> getOrder(int id) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Order/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return OrderDetail.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load order');
  }

  Future<void> updateStatus(int id, int status) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    final body = <String, dynamic>{'status': status};
    if (status == 2) body['shippedDate'] = DateTime.now().toIso8601String();
    final response = await HttpClient.put(
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
