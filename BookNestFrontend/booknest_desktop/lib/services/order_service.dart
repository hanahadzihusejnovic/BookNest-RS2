import 'dart:convert';
import '../layouts/constants.dart';
import '../models/order.dart';
import '../models/order_detail.dart';
import 'http_client.dart';

class OrderService {
  Future<List<Order>> getOrders({int pageSize = 200}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/Order')
        .replace(queryParameters: {'PageSize': pageSize.toString()});

    final response = await HttpClient.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Order.fromJson(e)).toList();
    }
    throw Exception('Failed to load orders');
  }

  Future<OrderDetail> getOrder(int id) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Order/$id'),
    );
    if (response.statusCode == 200) {
      return OrderDetail.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load order');
  }

  Future<void> updateStatus(int id, int status, {String? cancellationReason}) async {
    final body = <String, dynamic>{'status': status};
    if (status == 1) body['shippedDate'] = DateTime.now().toIso8601String();
    if (cancellationReason != null) body['cancellationReason'] = cancellationReason;
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Order/$id'),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update order status: ${response.statusCode} ${response.body}');
    }
  }
}
