import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../services/dashboard_service.dart';
import 'users_screen.dart';
import 'books_screen.dart';
import 'orders_screen.dart';
import 'events_screen.dart';
import 'reservations_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = DashboardService();

  int? _totalUsers;
  int? _totalBooks;
  int? _pendingOrders;
  int? _upcomingEvents;
  int? _pendingReservations;
  List<Map<String, dynamic>> _categoryStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _dashboardService.getTotalUsers(),
        _dashboardService.getTotalBooks(),
        _dashboardService.getPendingOrdersCount(),
        _dashboardService.getUpcomingEventsCount(),
        _dashboardService.getPendingReservationsCount(),
      ]);

      final categoryStats = await _dashboardService.getCategoryStats();

      if (!mounted) return;
      setState(() {
        _totalUsers = results[0];
        _totalBooks = results[1];
        _pendingOrders = results[2];
        _upcomingEvents = results[3];
        _pendingReservations = results[4];
        _categoryStats = categoryStats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _fmt(int? value) => _isLoading ? '...' : (value?.toString() ?? '-');

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ADMIN DASHBOARD',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Users, Books, Events
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.person_outline,
                    label: 'USERS',
                    statLabel: 'Total:',
                    value: _fmt(_totalUsers),
                    isLoading: _isLoading,
                    onTap: () => _navigate(const UsersScreen()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    icon: Icons.menu_book_outlined,
                    label: 'BOOKS',
                    statLabel: 'Total:',
                    value: _fmt(_totalBooks),
                    isLoading: _isLoading,
                    onTap: () => _navigate(const BooksScreen()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_outlined,
                    label: 'EVENTS',
                    statLabel: 'Upcoming:',
                    value: _fmt(_upcomingEvents),
                    isLoading: _isLoading,
                    onTap: () => _navigate(const EventsScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom row: Orders, Reservations
            Row(
              children: [
                const Spacer(),
                Expanded(
                  flex: 3,
                  child: _StatCard(
                    icon: Icons.shopping_cart_outlined,
                    label: 'ORDERS',
                    statLabel: 'Active:',
                    value: _fmt(_pendingOrders),
                    isLoading: _isLoading,
                    onTap: () => _navigate(const OrdersScreen()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: _StatCard(
                    icon: Icons.confirmation_number_outlined,
                    label: 'RESERVATIONS',
                    statLabel: 'Active:',
                    value: _fmt(_pendingReservations),
                    isLoading: _isLoading,
                    onTap: () => _navigate(const ReservationsScreen()),
                  ),
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Statistics',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Most Popular Book Categories',
              style: TextStyle(
                color: AppColors.darkBrown,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Bar chart
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.darkBrown),
              )
            else if (_categoryStats.isEmpty)
              const Text(
                'No data available.',
                style: TextStyle(color: AppColors.mediumBrown),
              )
            else
              _CategoryBarChart(stats: _categoryStats),
          ],
        ),
      ),
    );
  }
}

class _CategoryBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> stats;

  const _CategoryBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxY = stats
        .map((e) => (e['orderCount'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY + 2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.darkBrown,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${stats[groupIndex]['categoryName']}\n${rod.toY.toInt()} orders',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= stats.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      stats[index]['categoryName'],
                      style: const TextStyle(
                        color: AppColors.darkBrown,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  if (value % 2 != 0) return const SizedBox.shrink();
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.darkBrown.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: stats.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['orderCount'] as int).toDouble(),
                  color: AppColors.darkBrown,
                  width: 32,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String statLabel;
  final String value;
  final bool isLoading;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.statLabel,
    required this.value,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            statLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),

          const SizedBox(height: 16),

          SizedBox(
            width: 130,
            height: 34,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.darkBrown,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Click for more\ndetails',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}