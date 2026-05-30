import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';
import '../models/event_category.dart';

class EventCategoryService {
  Future<List<EventCategory>> getCategories() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/EventCategory?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? [];
      return items.map((e) => EventCategory.fromJson(e)).toList();
    }
    throw Exception('Failed to load event categories');
  }
}
