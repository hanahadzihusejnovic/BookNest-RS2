import 'package:flutter/material.dart';
import '../layouts/constants.dart';
import '../screens/dashboard_screen.dart';
import '../screens/users_screen.dart';
import '../screens/books_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/events_screen.dart';
import '../screens/reservations_screen.dart';
import '../screens/settings_screen.dart';

class AppLayout extends StatelessWidget {
  final String pageTitle;
  final Widget body;

  const AppLayout({
    super.key,
    required this.pageTitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      drawer: _AdminDrawer(currentPage: pageTitle),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: BookNest logo + hamburger
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BookNest',
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'World of your stories!',
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (ctx) => GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: const Icon(
                            Icons.menu,
                            color: AppColors.darkBrown,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Page title + bell
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pageTitle,
                          style: const TextStyle(
                            color: AppColors.darkBrown,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.notifications_none,
                        color: AppColors.darkBrown,
                        size: 26,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/* ----------------------- DRAWER ----------------------- */

class _AdminDrawer extends StatelessWidget {
  final String currentPage;

  const _AdminDrawer({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkBrown,
      width: 280,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BookNest',
                    style: TextStyle(
                      color: AppColors.pageBg,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'World of your stories!',
                    style: TextStyle(
                      color: AppColors.pageBg.withValues(alpha: 0.85),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            _DrawerItem(
              title: 'DASHBOARD',
              isActive: currentPage == 'ADMIN DASHBOARD',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'ADMIN DASHBOARD') {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()));
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'USERS',
              isActive: currentPage == 'USERS',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'USERS') {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const UsersScreen()));
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'BOOKS',
              isActive: currentPage == 'BOOKS',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'BOOKS') {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const BooksScreen()));
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'ORDERS',
              isActive: currentPage == 'ORDERS',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'ORDERS') {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const OrdersScreen()));
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'EVENTS',
              isActive: currentPage == 'EVENTS',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'EVENTS') {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const EventsScreen()));
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'RESERVATIONS',
              isActive: currentPage == 'RESERVATIONS',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'RESERVATIONS') {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const ReservationsScreen()));
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'SETTINGS',
              isActive: currentPage == 'SETTINGS',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'SETTINGS') {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()));
                }
              },
            ),
            _DrawerDivider(),

            const Spacer(),

            // MY PROFILE
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.pageBg, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          color: AppColors.pageBg, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MY PROFILE',
                      style: TextStyle(
                        color: AppColors.pageBg,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.mediumBrown : AppColors.pageBg,
            fontSize: 20,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w300,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        color: AppColors.pageBg.withValues(alpha: 0.35),
        thickness: 1,
        height: 1,
      ),
    );
  }
}
