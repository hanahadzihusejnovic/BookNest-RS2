import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/cart.dart';

class CartService {
  Future<CartModel> getMyCart() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/Cart/my-cart'),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load cart');
  }

  Future<CartModel> addItem(int bookId, int quantity) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/Cart/add-item'),
      body: jsonEncode({'bookId': bookId, 'quantity': quantity}),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to add item');
  }

  Future<CartModel> updateItem(int cartItemId, int quantity) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/Cart/update-item/$cartItemId'),
      body: jsonEncode(quantity),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update item');
  }

  Future<CartModel> removeItem(int cartItemId) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Cart/remove-item/$cartItemId'),
    );
    if (response.statusCode == 200) {
      return CartModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to remove item');
  }

  Future<void> clearCart() async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/Cart/clear'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to clear cart');
    }
  }
}
