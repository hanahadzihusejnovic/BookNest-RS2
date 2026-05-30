import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/order.dart';

class OrderService {
  Future<List<OrderModel>> getMyOrders() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Order/my-orders'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => OrderModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load orders');
  }

  Future<void> cancelOrder(int id, String cancellationReason) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Order/$id/cancel'),
      body: jsonEncode(cancellationReason),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to cancel order');
    }
  }
}
