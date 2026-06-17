import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/reservation_detail.dart';
import '../services/reservation_service.dart';
import '../services/http_client.dart';
import '../widgets/admin_table.dart';
import 'reservations_screen.dart';

class ReservationDetailScreen extends StatefulWidget {
  final int reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final _reservationService = ReservationService();
  ReservationDetail? _reservation;
  bool _isLoading = true;
  bool _isValidating = false;
  Map<String, dynamic>? _validationResult;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final r = await _reservationService.getReservation(widget.reservationId);
      if (!mounted) return;
      setState(() {
        _reservation = r;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppSnackBar.show(context, 'Failed to load reservation', isError: true);
      }
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}.${d.month}.${d.year}';
  }

  String _fmtDateTime(DateTime d) {
    return '${d.day}.${d.month}.${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static const _reservationTransitions = {
    'Pending':   [('Confirmed', 2), ('Cancelled', 3)],
    'Confirmed': [('Cancelled', 3)],
  };

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFE53935);
      default:          return AppColors.mediumBrown;
    }
  }

  Future<void> _validateTicket(String token) async {
    setState(() {
      _isValidating = true;
      _validationResult = null;
    });
    try {
      final response = await HttpClient.get(
        Uri.parse('${AppConstants.baseUrl}/EventReservation/validate-ticket/$token'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _validationResult = jsonDecode(response.body));
      } else {
        AppSnackBar.show(context, 'Validation request failed.', isError: true);
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _changeStatus() async {
    final r = _reservation;
    if (r == null) return;
    final options = _reservationTransitions[r.reservationStatus];
    if (options == null || options.isEmpty) return;

    final chosen = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkBrown,
        title: const Text('Change Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map((o) => ListTile(
                    title: Text(o.$1, style: const TextStyle(color: Colors.white)),
                    onTap: () => Navigator.pop(ctx, o.$2),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown)),
          ),
        ],
      ),
    );
    if (chosen == null || !mounted) return;

    String? cancellationReason;
    if (chosen == 3) {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.darkBrown,
          title: const Text('Cancellation Reason',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter reason...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.lightBrown)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.lightBrown)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.lightBrown))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm', style: TextStyle(color: Colors.white))),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      cancellationReason = reasonController.text.trim();
      if (cancellationReason.isEmpty) {
        AppSnackBar.show(context, 'Cancellation reason is required', isError: true);
        return;
      }
    }

    try {
      await _reservationService.updateStatus(r.id, chosen, cancellationReason: cancellationReason);
      if (mounted) {
        AppSnackBar.show(context, 'Status updated');
        _loadData();
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, 'Failed to update status', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'RESERVATIONS',
      onBack: () => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ReservationsScreen())),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkBrown))
          : _reservation == null
              ? const Center(
                  child: Text('Reservation not found.',
                      style: TextStyle(color: AppColors.mediumBrown)))
              : _buildContent(_reservation!),
    );
  }

  Widget _buildContent(ReservationDetail r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(r),
          const SizedBox(height: 32),
          _buildEventTable(r),
        ],
      ),
    );
  }

  Widget _buildHeader(ReservationDetail r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reservation #${r.id}',
                style: const TextStyle(
                    color: AppColors.darkBrown,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              _Badge(r.reservationStatus, color: _statusColor(r.reservationStatus)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reservation Info',
                            style: TextStyle(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        const SizedBox(height: 10),
                        DetailRow('User:', r.userFullName),
                        const SizedBox(height: 10),
                        DetailRow('Email:', r.userEmail),
                        if (r.userPhoneNumber != null) ...[
                          const SizedBox(height: 10),
                          DetailRow('Phone:', r.userPhoneNumber!),
                        ],
                        const SizedBox(height: 10),
                        DetailRow('Reservation Date:', _fmt(r.reservationDate)),
                        const SizedBox(height: 10),
                        DetailRow('Quantity:', '${r.quantity} ticket${r.quantity != 1 ? 's' : ''}'),
                        const SizedBox(height: 10),
                        DetailRow('Total:', r.totalPrice == 0 ? 'Free' : '${r.totalPrice.toStringAsFixed(2)} BAM'),
                        if (r.cancellationReason != null) ...[
                          const SizedBox(height: 10),
                          DetailRow('Cancellation Reason:', r.cancellationReason!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment',
                            style: TextStyle(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        const SizedBox(height: 10),
                        DetailRow('Method:', r.payment.paymentMethod),
                        const SizedBox(height: 10),
                        DetailRow('Amount:', r.payment.amount == 0 ? 'Free' : '${r.payment.amount.toStringAsFixed(2)} BAM'),
                        const SizedBox(height: 10),
                        DetailRow('Date:', _fmt(r.payment.paymentDate)),
                        const SizedBox(height: 10),
                        DetailRow('Status:', r.payment.isSuccessful ? 'Successful' : 'Failed'),
                        if (r.payment.transactionId != null) ...[
                          const SizedBox(height: 10),
                          DetailRow('Transaction ID:', r.payment.transactionId!),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 28),

        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_reservationTransitions.containsKey(r.reservationStatus))
              DetailActionButton(
                icon: Icons.swap_horiz,
                label: 'CHANGE STATUS',
                onTap: _changeStatus,
                width: 185,
              ),
            if (r.ticketQRCodeLink != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.darkBrown.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: r.ticketQRCodeLink!,
                  version: QrVersions.auto,
                  size: 169,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Ticket QR Code',
                  style: TextStyle(
                      color: AppColors.mediumBrown,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              SizedBox(
                width: 185,
                child: ElevatedButton.icon(
                  onPressed: _isValidating
                      ? null
                      : () => _validateTicket(r.ticketQRCodeLink!),
                  icon: _isValidating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.qr_code_scanner,
                          size: 16, color: Colors.white),
                  label: Text(
                    _isValidating ? 'Validating...' : 'Validate Ticket',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (_validationResult != null) ...[
                const SizedBox(height: 10),
                _TicketValidationCard(_validationResult!),
              ],
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEventTable(ReservationDetail r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Event Details',
            style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: const [
              SizedBox(width: 56),
              AdminColHeader('Event Name', flex: 3),
              AdminColHeader('Location', flex: 4),
              AdminColHeader('Date & Time', flex: 2),
              AdminColHeader('Ticket Price', flex: 2),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              AdminThumbnail(imageUrl: r.eventImageUrl, fallbackIcon: Icons.event_outlined),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: Text(r.eventName, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
              Expanded(flex: 4, child: Text(r.eventLocation, style: adminRowStyle, overflow: TextOverflow.ellipsis)),
              Expanded(flex: 2, child: Text(_fmtDateTime(r.eventDateTime), style: adminRowStyle)),
              Expanded(flex: 2, child: Text(r.ticketPrice == 0 ? 'Free' : '${r.ticketPrice.toStringAsFixed(2)} BAM', style: adminRowStyle)),
            ],
          ),
        ),
        Divider(color: AppColors.darkBrown.withValues(alpha: 0.25), thickness: 1, height: 12),
      ],
    );
  }
}

class _TicketValidationCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _TicketValidationCard(this.result);

  @override
  Widget build(BuildContext context) {
    final isValid = result['isValid'] == true;
    final color = isValid ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bg = isValid ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final border = isValid ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return Container(
      width: 185,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isValid ? Icons.check_circle : Icons.cancel,
                  color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                isValid ? 'VALID' : 'INVALID',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result['message'] ?? '',
            style: TextStyle(color: color, fontSize: 11),
          ),
          if (result['userFullName'] != null) ...[
            const SizedBox(height: 6),
            _VRow('Guest', result['userFullName']),
          ],
          if (result['quantity'] != null)
            _VRow('Tickets', '${result['quantity']}'),
          if (result['reservationStatus'] != null)
            _VRow('Status', result['reservationStatus']),
        ],
      ),
    );
  }
}

class _VRow extends StatelessWidget {
  final String label;
  final String value;

  const _VRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11),
          children: [
            TextSpan(
                text: '$label: ',
                style: TextStyle(
                    color: AppColors.darkBrown.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600)),
            TextSpan(
                text: value,
                style: TextStyle(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;

  const _Badge(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppColors.mediumBrown).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? AppColors.mediumBrown).withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.darkBrown,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
