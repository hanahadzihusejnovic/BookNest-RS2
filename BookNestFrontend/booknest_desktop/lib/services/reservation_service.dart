import 'dart:convert';
import '../layouts/constants.dart';
import '../models/reservation.dart';
import '../models/reservation_detail.dart';
import 'http_client.dart';

class ReservationService {
  Future<List<Reservation>> getReservations({int pageSize = 200}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/EventReservation')
        .replace(queryParameters: {'PageSize': pageSize.toString()});

    final response = await HttpClient.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((e) => Reservation.fromJson(e)).toList();
    }
    throw Exception('Failed to load reservations');
  }

  Future<ReservationDetail> getReservation(int id) async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/$id'),
    );
    if (response.statusCode == 200) {
      return ReservationDetail.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load reservation');
  }

  Future<void> updateStatus(int id, int status, {String? cancellationReason}) async {
    final body = <String, dynamic>{'reservationStatusId': status};
    if (cancellationReason != null) body['cancellationReason'] = cancellationReason;
    final response = await HttpClient.put(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/$id'),
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update reservation status: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> sendReminder(int id) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/$id/send-reminder'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send reminder: ${response.statusCode}');
    }
  }
}
