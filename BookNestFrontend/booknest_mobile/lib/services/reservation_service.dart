import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ReservationModel {
  final int id;
  final String eventName;
  final String eventLocation;
  final DateTime eventDateTime;
  final int quantity;
  final double totalPrice;
  final String reservationStatus;
  final String? ticketQRCodeLink;

  ReservationModel({
    required this.id,
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
      eventName: json['eventName'] ?? '',
      eventLocation: json['eventLocation'] ?? '',
      eventDateTime: DateTime.parse(json['eventDateTime']),
      quantity: json['quantity'],
      totalPrice: (json['totalPrice'] as num).toDouble(),
      reservationStatus: json['reservationStatus']?.toString() ?? '',
      ticketQRCodeLink: json['ticketQRCodeLink'],
    );
  }
}

class ReservationService {
  static const String baseUrl = 'http://10.0.2.2:7110/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ReservationModel> reserveEvent({
    required int eventId,
    required int quantity,
    required int paymentMethod,
    String? transactionId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/EventReservation/reserve'),
      headers: await _headers(),
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
    final response = await http.get(
      Uri.parse('$baseUrl/EventReservation/my-reservations'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => ReservationModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load reservations');
  }
}