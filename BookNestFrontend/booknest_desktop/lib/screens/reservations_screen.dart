import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/admin_table.dart';
import 'reservation_detail_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _reservationService = ReservationService();
  final _searchController = TextEditingController();

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

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFE53935);
      case 'attended':
        return AppColors.mediumBrown;
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return AppColors.darkBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'RESERVATIONS',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBrown.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style:
                    const TextStyle(color: AppColors.darkBrown, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search by event, user, reservation status',
                  hintStyle:
                      TextStyle(color: AppColors.mediumBrown, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: const [
                  AdminColHeader('Event', flex: 3),
                  AdminColHeader('User', flex: 3),
                  AdminColHeader('Reservation Date', flex: 3),
                  AdminColHeader('Reservation Status', flex: 3),
                  SizedBox(width: 250),
                ],
              ),
            ),
            Divider(
                color: AppColors.darkBrown.withValues(alpha: 0.25),
                thickness: 1,
                height: 12),

            // List
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
                                    ],
                                    actions: [
                                      AdminActionButton(
                                        label: 'Send a\nreminder!',
                                        onPressed: () async {
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
                                        ),
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
    _searchController.dispose();
    super.dispose();
  }
}
