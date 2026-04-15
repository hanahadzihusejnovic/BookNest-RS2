import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../models/cart.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';

class CheckoutScreen extends StatefulWidget {
  final CartModel cart;

  const CheckoutScreen({
    super.key,
    required this.cart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _authService = AuthService();

  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';

  String _address = '';
  String _city = '';
  String _country = '';
  String _postalCode = '';

  String? _addressError;
  String? _cityError;
  String? _countryError;
  String? _postalCodeError;

  String _paymentMethod = 'CashOnDelivery';
  CardFieldInputDetails? _cardDetails;

  bool _isLoading = true;
  bool _isSubmitting = false;


  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/User/current-user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _firstName = data['firstName'] ?? '';
            _lastName = data['lastName'] ?? '';
            _email = data['emailAddress'] ?? '';
            _phone = data['phoneNumber'] ?? '';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitOrder() async {
    setState(() {
      _addressError = null;
      _cityError = null;
      _countryError = null;
      _postalCodeError = null;
    });

    bool hasError = false;

    if (_address.isEmpty) {
      setState(() => _addressError = 'Address is required');
      hasError = true;
    }
    if (_city.isEmpty) {
      setState(() => _cityError = 'City is required');
      hasError = true;
    }
    if (_postalCode.isEmpty) {
      setState(() => _postalCodeError = 'Postal code is required');
      hasError = true;
    }
    if (_country.isEmpty) {
      setState(() => _countryError = 'Country is required');
      hasError = true;
    }

    if (hasError) return;

    if (_paymentMethod == 'Card' &&
        (_cardDetails == null || !(_cardDetails!.complete))) {
      AppSnackBar.show(context, 'Please enter valid card details.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('Not authenticated');

      final userId = await _authService.getUserId();

      String? paymentIntentId;

      // Ako je plaćanje karticom — kreiraj PaymentIntent i potvrdi ga putem Stripea
      if (_paymentMethod == 'Card') {
        // 1. Kreiraj PaymentIntent na backendu
        final intentResponse = await http.post(
          Uri.parse('${AppConstants.baseUrl}/Order/create-payment-intent'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'amount': widget.cart.totalPrice}),
        );

        if (intentResponse.statusCode != 200) {
          throw Exception('Failed to create payment intent');
        }

        final intentData = jsonDecode(intentResponse.body);
        final clientSecret = intentData['clientSecret'] as String;
        paymentIntentId = intentData['paymentIntentId'] as String;

        // 2. Potvrdi plaćanje putem Stripe SDK-a
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
          data: const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );
      }

      // 3. Kreiraj order na backendu
      final body = {
        'userId': userId ?? 0,
        'shipping': {
          'address': _address,
          'city': _city,
          'country': _country,
          'postalCode': _postalCode,
        },
        'paymentMethod': _paymentMethod == 'CashOnDelivery' ? 0 : 1,
        if (paymentIntentId != null) 'transactionId': paymentIntentId,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/Order/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        try {
          final cartService = CartService();
          await cartService.clearCart();
        } catch (_) {
          // clearCart greška ne blokira order success flow
        }

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.pageBg,
            title: Text(
              'Order placed!',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Text(
              'Your order has been successfully placed.',
              style: TextStyle(color: AppColors.darkBrown),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBrown,
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'PURCHASE INFORMATION',
      showBackButton: true,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book information
                  _SectionCard(
                    title: 'Book information',
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: widget.cart.cartItems.length > 3
                            ? 300
                            : double.infinity,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: widget.cart.cartItems.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _InfoRow('Title', item.bookTitle),
                                        _InfoRow(
                                            'Author', item.bookAuthor ?? '-'),
                                        _InfoRow('Quantity',
                                            item.quantity.toString()),
                                        _InfoRow(
                                          'Price',
                                          '${item.subtotal.toStringAsFixed(2)} BAM',
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
                                      child: item.bookImageUrl != null &&
                                              item.bookImageUrl!.isNotEmpty
                                          ? Image.network(
                                              item.bookImageUrl!,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  _imageFallback(),
                                            )
                                          : _imageFallback(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
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
                        if (_phone.isNotEmpty) _InfoRow('Phone', _phone),
                        _InfoRow('Email', _email),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Shipping information
                  _SectionCard(
                    title: 'Shipping information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShippingField(
                          label: 'Address',
                          initialValue: _address,
                          error: _addressError,
                          onChanged: (v) => setState(() {
                            _address = v;
                            _addressError = null;
                          }),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ShippingField(
                                label: 'City',
                                initialValue: _city,
                                error: _cityError,
                                onChanged: (v) => setState(() {
                                  _city = v;
                                  _cityError = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ShippingField(
                                label: 'Postal code',
                                initialValue: _postalCode,
                                error: _postalCodeError,
                                onChanged: (v) => setState(() {
                                  _postalCode = v;
                                  _postalCodeError = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ShippingField(
                          label: 'Country',
                          initialValue: _country,
                          error: _countryError,
                          onChanged: (v) => setState(() {
                            _country = v;
                            _countryError = null;
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment method
                  _SectionCard(
                    title: 'Payment method',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PaymentOption(
                          label: 'Cash on delivery',
                          value: 'CashOnDelivery',
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CardFormField(
                              style: CardFormStyle(
                                backgroundColor: AppColors.darkBrown,
                                textColor: Colors.white,
                                placeholderColor: Colors.white54,
                                borderColor: Colors.transparent,
                                borderRadius: 10,
                                fontSize: 14,
                              ),
                              onCardChanged: (details) {
                                setState(() => _cardDetails = details);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.darkBrown,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TOTAL: ${widget.cart.totalPrice.toStringAsFixed(2)} BAM',
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
                          onPressed: _isSubmitting ? null : _submitOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBrown,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'CONFIRM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'BACK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
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

  Widget _imageFallback() {
    return Container(
      color: AppColors.pageBg.withValues(alpha: 0.5),
      child: Icon(
        Icons.menu_book_rounded,
        color: AppColors.darkBrown.withValues(alpha: 0.5),
        size: 24,
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
        border: Border.all(
          color: AppColors.darkBrown.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.darkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
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
        style: TextStyle(
          color: AppColors.darkBrown,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ShippingField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? error;

  const _ShippingField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            style: const TextStyle(
              color: AppColors.darkBrown,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: error != null
                    ? Colors.red
                    : AppColors.darkBrown.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 1,
          color: error != null ? Colors.red : AppColors.darkBrown,
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error!,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.red,
            ),
          ),
        ],
      ],
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
        Text(
          label,
          style: TextStyle(
            color: AppColors.darkBrown,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
