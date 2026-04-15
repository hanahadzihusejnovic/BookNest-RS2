import 'dart:convert';
import '../layouts/constants.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/tbr.dart';

enum ReadingStatus { toBeRead, reading, read }

extension ReadingStatusExtension on ReadingStatus {
  int get value {
    switch (this) {
      case ReadingStatus.toBeRead: return 0;
      case ReadingStatus.reading: return 1;
      case ReadingStatus.read: return 2;
    }
  }

  String get label {
    switch (this) {
      case ReadingStatus.toBeRead: return 'To Be Read';
      case ReadingStatus.reading: return 'Reading';
      case ReadingStatus.read: return 'Read';
    }
  }
}

class TBRService {
  final AuthService _authService = AuthService();

  Future<bool> isBookInTBR(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/TBRList/check/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as bool;
    }
    return false;
  }

  Future<void> addToTBR(int bookId, ReadingStatus status) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/TBRList/add'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bookId': bookId,
        'readingStatus': status.value,
      }),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to add to TBR list');
    }
  }

  Future<void> updateTBRStatus(int bookId, ReadingStatus status) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/TBRList/update-status/$bookId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(status.value),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to update TBR status');
    }
  }

  Future<void> removeFromTBR(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/TBRList/remove/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from TBR list');
    }
  }

  Future<ReadingStatus?> getTBRStatus(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/TBRList/my-tbr-list'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      final item = list.cast<Map<String, dynamic>?>().firstWhere(
        (e) => e?['bookId'] == bookId,
        orElse: () => null,
      );
      if (item != null) {
        return ReadingStatus.values[item['readingStatus'] as int];
      }
    }
    return null;
  }

  Future<List<TBRItemModel>> getMyTBRList({int? statusFilter}) async {
    final token = await _authService.getToken();
    final url = statusFilter != null
        ? '${AppConstants.baseUrl}/TBRList/my-tbr-list?status=$statusFilter'
        : '${AppConstants.baseUrl}/TBRList/my-tbr-list';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => TBRItemModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load TBR list');
  }

  Future<void> removeFromTBRById(int bookId) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/TBRList/remove/$bookId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove from TBR list');
    }
  }
}