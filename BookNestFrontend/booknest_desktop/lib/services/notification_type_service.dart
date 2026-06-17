import 'dart:convert';
import '../layouts/constants.dart';
import '../models/notification_type.dart';
import 'http_client.dart';

class NotificationTypeService {
  Future<List<NotificationType>> getAll() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/NotificationType?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => NotificationType.fromJson(e)).toList();
    }
    throw Exception('Failed to load notification types');
  }

  Future<NotificationType> create(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/NotificationType'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return NotificationType.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create notification type');
  }

  Future<NotificationType> update(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/NotificationType/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return NotificationType.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update notification type');
  }

  Future<void> delete(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/NotificationType/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification type');
    }
  }
}
