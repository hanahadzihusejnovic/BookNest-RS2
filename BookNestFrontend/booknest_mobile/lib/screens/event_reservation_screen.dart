import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/event.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../services/auth_service.dart';
import '../services/reservation_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EventReservationScreen extends StatefulWidget {
  final EventModel event;
  final int quantity;

  const EventReservationScreen({
    super.key,
    required this.event,
    required this.quantity,
  });

  @override
  State<EventReservationScreen> createState() =>
      _EventReservationScreenState();
}

class _EventReservationScreenState extends State<EventReservationScreen> {
  final _authService = AuthService();
  final _reservationService = ReservationService();

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _address = '';
  String _phone = '';

  bool _isLoading = true;
  bool _isSubmitting = false;

  String _paymentMethod = 'CashOnArrival';
  final _cardNumberController = TextEditingController();
  final _cvcController = TextEditingController();
  final _expiryController = TextEditingController();

  static const String baseUrl = 'http://10.0.2.2:7110/api';

  double get _totalPrice => widget.event.ticketPrice * widget.quantity;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cvcController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/User/current-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _firstName = data['firstName'] ?? '';
          _lastName = data['lastName'] ?? '';
          _email = data['emailAddress'] ?? '';
          _phone = data['phoneNumber'] ?? '';
          _address = data['address'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReservation() async {
    if (_paymentMethod == 'Card' &&
        (_cardNumberController.text.isEmpty ||
            _cvcController.text.isEmpty ||
            _expiryController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all card details.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reservation = await _reservationService.reserveEvent(
        eventId: widget.event.id,
        quantity: widget.quantity,
        paymentMethod: _paymentMethod == 'CashOnArrival' ? 0 : 1,
        transactionId: _paymentMethod == 'Card'
            ? '${_cardNumberController.text}-${_cvcController.text}-${_expiryController.text}'
            : null,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.pageBg,
          title: Text('Reservation confirmed!',
              style: TextStyle(
                  color: AppColors.darkBrown, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Your spot has been reserved successfully.',
                    style: TextStyle(color: AppColors.darkBrown)),
                if (reservation.ticketQRCodeLink != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: QrImageView(
                      data: reservation.ticketQRCodeLink!,
                      version: QrVersions.auto,
                      size: 160,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Scan for access!',
                      style: TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.darkBrown),
              child:
                  const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _eventFallback() {
    return Container(
      color: AppColors.mediumBrown.withOpacity(0.35),
      child: Icon(Icons.event,
          color: AppColors.darkBrown.withOpacity(0.45), size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return AppLayout(
      pageTitle: 'RESERVATION INFORMATION',
      showBackButton: true,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event information
                  _SectionCard(
                    title: 'Event information',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow('Name', event.name),
                              _InfoRow('Organizer', event.organizerName),
                              _InfoRow('Date & Time', event.formattedDate),
                              _InfoRow('Tickets', '${widget.quantity}'),
                              _InfoRow(
                                'Price per ticket',
                                event.ticketPrice == 0
                                    ? 'Free'
                                    : '${event.ticketPrice.toStringAsFixed(2)} BAM',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 80,
                            height: 100,
                            child: event.imageUrl != null &&
                                    event.imageUrl!.isNotEmpty
                                ? Image.network(
                                    event.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _eventFallback(),
                                  )
                                : _eventFallback(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User information
                  _SectionCard(
                    title: 'User information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow('First name', _firstName),
                        _InfoRow('Last name', _lastName),
                        if (_address.isNotEmpty) _InfoRow('Address', _address),
                        if (_phone.isNotEmpty) _InfoRow('Phone', _phone),
                        _InfoRow('Email', _email),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment method
                  if (event.ticketPrice > 0)
                    _SectionCard(
                      title: 'Payment method',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PaymentOption(
                            label: 'Cash upon arrival',
                            value: 'CashOnArrival',
                            groupValue: _paymentMethod,
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v!),
                          ),
                          _PaymentOption(
                            label: 'Card',
                            value: 'Card',
                            groupValue: _paymentMethod,
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v!),
                          ),
                          if (_paymentMethod == 'Card') ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.darkBrown,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  _CardField(
                                    controller: _cardNumberController,
                                    label: 'Card number',
                                    hint: '1234 1234 1234 1234',
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _CardField(
                                          controller: _cvcController,
                                          label: 'CVC',
                                          hint: '123',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _CardField(
                                          controller: _expiryController,
                                          label: 'Expiration date',
                                          hint: 'MM/YY',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    _SectionCard(
                      title: 'Payment method',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppColors.darkBrown.withOpacity(0.6),
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'This event is free — no payment required.',
                            style: TextStyle(
                                color: AppColors.darkBrown.withOpacity(0.7),
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkBrown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.ticketPrice == 0
                          ? 'TOTAL: Free'
                          : 'TOTAL: ${_totalPrice.toStringAsFixed(2)} BAM',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isSubmitting ? null : _submitReservation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBrown,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('CONFIRM',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBrown,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('BACK',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

/* ----------------------- WIDGETS ----------------------- */

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBrown.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: ${value.isEmpty ? '-' : value}',
        style: TextStyle(color: AppColors.darkBrown, fontSize: 13),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: AppColors.darkBrown,
        ),
        Text(label,
            style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _CardField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.7), fontSize: 11)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4), fontSize: 12),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.4))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}