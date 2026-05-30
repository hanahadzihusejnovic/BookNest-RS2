import 'dart:convert';
import '../layouts/constants.dart';
import 'http_client.dart';

class ReservationModel {
  final int id;
  final int eventId;
  final String eventName;
  final String eventLocation;
  final DateTime eventDateTime;
  final int quantity;
  final double totalPrice;
  final String reservationStatus;
  final String? ticketQRCodeLink;

  static String _parseStatus(dynamic value) {
    switch (value) {
      case 0: return 'Pending';
      case 1: return 'Confirmed';
      case 2: return 'Cancelled';
      case 3: return 'Attended';
      default: return value?.toString() ?? '';
    }
  }

  ReservationModel({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventLocation,
    required this.eventDateTime,
    required this.quantity,
    required this.totalPrice,
    required this.reservationStatus,
    this.ticketQRCodeLink,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'],
      eventId: json['eventId'] ?? 0,
      eventName: json['eventName'] ?? '',
      eventLocation: json['eventLocation'] ?? '',
      eventDateTime: DateTime.parse(json['eventDateTime']),
      quantity: json['quantity'],
      totalPrice: (json['totalPrice'] as num).toDouble(),
      reservationStatus: _parseStatus(json['reservationStatus']),
      ticketQRCodeLink: json['ticketQRCodeLink'],
    );
  }
}

class ReservationService {
  Future<ReservationModel> reserveEvent({
    required int eventId,
    required int quantity,
    required int paymentMethod,
    String? transactionId,
  }) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/reserve'),
      body: jsonEncode({
        'eventId': eventId,
        'quantity': quantity,
        'paymentMethod': paymentMethod,
        if (transactionId != null) 'transactionId': transactionId,
      }),
    );
    if (response.statusCode == 200) {
      return ReservationModel.fromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Failed to reserve event');
  }

  Future<List<ReservationModel>> getMyReservations() async {
    final response = await HttpClient.get(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/my-reservations'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ReservationModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load reservations');
  }

  Future<void> cancelReservation(int id, String cancellationReason) async {
    final response = await HttpClient.post(
      Uri.parse('${AppConstants.baseUrl}/EventReservation/$id/cancel'),
      body: jsonEncode(cancellationReason),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to cancel reservation');
    }
  }
}
