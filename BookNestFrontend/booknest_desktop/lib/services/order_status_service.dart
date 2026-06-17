import 'dart:convert';
import '../layouts/constants.dart';
import '../models/order_status.dart';
import 'http_client.dart';

class OrderStatusService {
  Future<List<OrderStatus>> getAll() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/OrderStatus?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => OrderStatus.fromJson(e)).toList();
    }
    throw Exception('Failed to load order statuses');
  }

  Future<OrderStatus> create(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/OrderStatus'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return OrderStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create order status');
  }

  Future<OrderStatus> update(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/OrderStatus/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return OrderStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update order status');
  }

  Future<void> delete(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/OrderStatus/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete order status');
    }
  }
}
