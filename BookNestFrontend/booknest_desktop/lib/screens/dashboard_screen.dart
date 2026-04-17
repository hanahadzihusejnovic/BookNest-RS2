import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import '../layouts/constants.dart';
import '../services/dashboard_service.dart';
import 'users_screen.dart';
import 'books_screen.dart';

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
      ]);

      if (!mounted) return;
      setState(() {
        _totalUsers = results[0];
        _totalBooks = results[1];
        _pendingOrders = results[2];
        _upcomingEvents = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _fmt(int? value) => _isLoading ? '...' : (value?.toString() ?? '-');

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'ADMIN DASHBOARD',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stat cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.person_outline,
                    label: 'USERS',
                    statLabel: 'Total:',
                    value: _fmt(_totalUsers),
                    isLoading: _isLoading,
                    onTap: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const UsersScreen())),
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
                    onTap: () => Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const BooksScreen())),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    icon: Icons.shopping_cart_outlined,
                    label: 'ORDERS',
                    statLabel: 'Active:',
                    value: _fmt(_pendingOrders),
                    isLoading: _isLoading,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    icon: Icons.grid_view_outlined,
                    label: 'EVENTS',
                    statLabel: 'Upcoming:',
                    value: _fmt(_upcomingEvents),
                    isLoading: _isLoading,
                    onTap: () {},
                  ),
                ),
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
          ],
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
          // Icon + label
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
                  color: Colors.white,
                  strokeWidth: 2,
                ),
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
                  borderRadius: BorderRadius.circular(8),
                ),
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
