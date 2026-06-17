import 'dart:convert';
import '../layouts/constants.dart';
import '../models/payment_method.dart';
import 'http_client.dart';

class PaymentMethodService {
  Future<List<PaymentMethod>> getAll() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/PaymentMethod?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => PaymentMethod.fromJson(e)).toList();
    }
    throw Exception('Failed to load payment methods');
  }

  Future<PaymentMethod> create(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/PaymentMethod'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return PaymentMethod.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create payment method');
  }

  Future<PaymentMethod> update(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/PaymentMethod/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return PaymentMethod.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update payment method');
  }

  Future<void> delete(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/PaymentMethod/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete payment method');
    }
  }
}
