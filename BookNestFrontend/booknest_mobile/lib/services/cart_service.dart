import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import 'auth_service.dart';

class CartService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<CartModel> getMyCart() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/Cart/my-cart'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load cart');
  }

  Future<CartModel> addItem(int bookId, int quantity) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/Cart/add-item'),
      headers: await _headers(),
      body: jsonEncode({'bookId': bookId, 'quantity': quantity}),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add item');
  }

  Future<CartModel> updateItem(int cartItemId, int quantity) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/Cart/update-item/$cartItemId'),
      headers: await _headers(),
      body: jsonEncode(quantity),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update item');
  }

  Future<CartModel> removeItem(int cartItemId) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/Cart/remove-item/$cartItemId'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to remove item');
  }

  Future<void> clearCart() async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/Cart/clear'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to clear cart');
    }
  }
}