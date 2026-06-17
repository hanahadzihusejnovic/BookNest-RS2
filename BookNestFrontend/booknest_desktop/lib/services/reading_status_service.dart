import 'dart:convert';
import '../layouts/constants.dart';
import '../models/reading_status.dart';
import 'http_client.dart';

class ReadingStatusService {
  Future<List<ReadingStatus>> getAll() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/ReadingStatus?RetrieveAll=true'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => ReadingStatus.fromJson(e)).toList();
    }
    throw Exception('Failed to load reading statuses');
  }

  Future<ReadingStatus> create(String name) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/ReadingStatus'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ReadingStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create reading status');
  }

  Future<ReadingStatus> update(int id, String name) async {
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/ReadingStatus/$id'),
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 200) {
      return ReadingStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update reading status');
  }

  Future<void> delete(int id) async {
    final response = await HttpClient.delete(
      Uri.parse('${AppConstants.baseUrl}/ReadingStatus/$id'),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reading status');
    }
  }
}
