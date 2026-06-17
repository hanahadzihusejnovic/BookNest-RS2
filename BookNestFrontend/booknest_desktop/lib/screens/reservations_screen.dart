import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import 'dashboard_screen.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/admin_table.dart';
import 'reservation_detail_screen.dart';
import 'lookup_manage_screen.dart';
import '../services/reservation_status_service.dart';
import '../services/notification_type_service.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _reservationService = ReservationService();
  final _searchController = TextEditingController();
  Timer? _refreshTimer;

  List<Reservation> _allReservations = [];
  List<Reservation> _filteredReservations = [];
  bool _isLoading = true;

  static const int _pageSize = 10;
  int _currentPage = 0;

  List<Reservation> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredReservations.length);
    return _filteredReservations.sublist(start, end);
  }

  int get _totalPages => (_filteredReservations.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadReservations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadReservations();
    });
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    try {
      final reservations = await _reservationService.getReservations();
      if (!mounted) return;
      setState(() {
        _allReservations = reservations;
        _filteredReservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackBar.show(context, 'Failed to load reservations', isError: true);
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _currentPage = 0;
      _filteredReservations = q.isEmpty
          ? _allReservations
          : _allReservations.where((r) {
              return r.eventName.toLowerCase().contains(q) ||
                  r.userFullName.toLowerCase().contains(q) ||
                  r.reservationStatus.toLowerCase().contains(q);
            }).toList();
    });
  }

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year}';

  void _showManageDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ManageDataModal(
        options: [
          ManageDataOption(
            label: 'Reservation Status',
            onTap: () {
              Navigator.pop(ctx);
              final svc = ReservationStatusService();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LookupManageScreen(
                    title: 'Reservation Status',
                    getAll: () async => (await svc.getAll())
                        .map((e) => LookupItem(id: e.id, name: e.name))
                        .toList(),
                    create: (name) => svc.create(name),
                    update: (id, name) => svc.update(id, name),
                    delete: svc.delete,
                    backScreen: () => const ReservationsScreen(),
                  ),
                ),
              );
            },
          ),
          ManageDataOption(
            label: 'Notification Type',
            onTap: () {
              Navigator.pop(ctx);
              final svc = NotificationTypeService();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LookupManageScreen(
                    title: 'Notification Type',
                    getAll: () async => (await svc.getAll())
                        .map((e) => LookupItem(id: e.id, name: e.name))
                        .toList(),
                    create: (name) => svc.create(name),
                    update: (id, name) => svc.update(id, name),
                    delete: svc.delete,
                    backScreen: () => const ReservationsScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  pw.Document _buildReservationsDoc() {
    final doc = pw.Document();
    final now = DateTime.now();
    final reservations = _filteredReservations;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Reservations Report',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
                'Generated: ${now.day}.${now.month}.${now.year}  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text('Total reservations: ${reservations.length}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 12),
            pw.Divider(),
          ],
        ),
        build: (_) => [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(2.5),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  '#',
                  'Event',
                  'User',
                  'Reservation Date',
                  'Status',
                  'Price (BAM)',
                ].map((h) => pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6, vertical: 5),
                      child: pw.Text(h,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    )).toList(),
              ),
              ...reservations.asMap().entries.map((entry) {
                final i = entry.key;
                final r = entry.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: i.isEven ? PdfColors.white : PdfColors.grey50),
                  children: [
                    '${i + 1}',
                    r.eventName,
                    r.userFullName,
                    _formatDate(r.reservationDate),
                    r.reservationStatus,
                    r.totalPrice == 0 ? 'Free' : r.totalPrice.toStringAsFixed(2),
                  ].map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: pw.Text(cell,
                            style: const pw.TextStyle(fontSize: 9)),
                      )).toList(),
                );
              }),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total revenue: ${reservations.where((r) => r.reservationStatus != 'Cancelled').fold(0.0, (s, r) => s + r.totalPrice).toStringAsFixed(2)} BAM',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  Future<void> _generatePdf() async {
    final doc = _buildReservationsDoc();
    final now = DateTime.now();
    final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
    final filename = 'reservations_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
    final file = File('$downloadsPath\\$filename');
    await file.writeAsBytes(await doc.save());
    if (mounted) {
      AppSnackBar.show(context, 'Report saved to Downloads\\$filename');
    }
  }

  Future<void> _printPdf() async {
    final doc = _buildReservationsDoc();
    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Reservations Report',
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFE53935);
      default:
        return AppColors.darkBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'RESERVATIONS',
      onBack: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _showManageDataDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    'Manage Data',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _generatePdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  child: const Text(
                    'Generate PDF Report',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _printPdf,
                  icon: const Icon(Icons.print, color: Colors.white, size: 18),
                  label: const Text(
                    'Print Report',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBrown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBrown.withValues(alpha: 0.4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.mediumBrown, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search by event, user, reservation status',
                        hintStyle: TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  AdminColHeader('Event', flex: 3),
                  AdminColHeader('User', flex: 3),
                  AdminColHeader('Reservation Date', flex: 3),
                  AdminColHeader('Reservation Status', flex: 3),
                  AdminColHeader('Price', flex: 2),
                  SizedBox(width: 250),
                ],
              ),
            ),
            Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.25),
                thickness: 1,
                height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.darkBrown))
                  : _filteredReservations.isEmpty
                      ? const Center(
                          child: Text('No reservations found.',
                              style: TextStyle(
                                  color: AppColors.mediumBrown, fontSize: 14)))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: _currentPageItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  color: AppColors.darkBrown
                                      .withValues(alpha: 0.15),
                                  thickness: 1,
                                  height: 1,
                                ),
                                itemBuilder: (context, index) {
                                  final r = _currentPageItems[index];
                                  return AdminListRow(
                                    columns: [
                                      AdminColumn(flex: 3, text: r.eventName),
                                      AdminColumn(flex: 3, text: r.userFullName),
                                      AdminColumn(flex: 3, text: _formatDate(r.reservationDate)),
                                      AdminColumn(
                                        flex: 3,
                                        text: r.reservationStatus,
                                        color: _statusColor(r.reservationStatus),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      AdminColumn(
                                        flex: 2,
                                        text: r.totalPrice == 0
                                            ? 'Free'
                                            : '${r.totalPrice.toStringAsFixed(2)} BAM',
                                      ),
                                    ],
                                    actions: [
                                      AdminActionButton(
                                        label: r.reservationStatus == 'Cancelled'
                                            ? 'Reservation\ncancelled'
                                            : 'Send a\nreminder!',
                                        backgroundColor: r.reservationStatus == 'Cancelled'
                                            ? AppColors.mediumBrown
                                            : null,
                                        onPressed: r.reservationStatus == 'Cancelled'
                                            ? null
                                            : () async {
                                                try {
                                                  await _reservationService.sendReminder(r.id);
                                                  if (!mounted) return;
                                                  AppSnackBar.show(context, 'Reminder sent successfully!');
                                                } catch (e) {
                                                  if (!mounted) return;
                                                  AppSnackBar.show(context, 'Failed to send reminder', isError: true);
                                                }
                                              },
                                      ),
                                      AdminActionButton(
                                        label: 'Click for more\ndetails',
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ReservationDetailScreen(reservationId: r.id),
                                          ),
                                        ).then((_) { if (mounted) _loadReservations(); }),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            PaginationBar(
                              currentPage: _currentPage,
                              totalPages: _totalPages,
                              onPrevious: () =>
                                  setState(() => _currentPage--),
                              onNext: () => setState(() => _currentPage++),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
