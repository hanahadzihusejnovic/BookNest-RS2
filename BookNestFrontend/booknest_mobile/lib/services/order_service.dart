import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import 'auth_service.dart';

class OrderService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<OrderModel>> getMyOrders() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/Order/my-orders'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => OrderModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load orders');
  }
}