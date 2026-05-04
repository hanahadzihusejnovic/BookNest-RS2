import 'package:flutter/material.dart';
import '../layouts/constants.dart';
import '../screens/home_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/events_screen.dart';
import '../screens/about_screen.dart';
import '../screens/settings_screen.dart';
import '../services/notification_service.dart';

class AppLayout extends StatelessWidget {
  final String pageTitle;
  final Widget body;
  final bool showBackButton;
  final bool showPageActionsRow;

  const AppLayout({
    super.key,
    required this.pageTitle,
    required this.body,
    this.showBackButton = false,
    this.showPageActionsRow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      drawer: _BookNestDrawer(currentPage: pageTitle),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gornji red: back/BookNest + hamburger
                  Row(
                    children: [
                      if (showBackButton) ...[
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back,
                              color: AppColors.darkBrown, size: 26),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BookNest',
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'World of your stories!',
                              style: TextStyle(
                                color: AppColors.darkBrown,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (ctx) => GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: Icon(Icons.menu,
                              color: AppColors.darkBrown, size: 26),
                        ),
                      ),
                    ],
                  ),

                  if (showPageActionsRow) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pageTitle,
                            style: TextStyle(
                              color: AppColors.darkBrown,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const NotificationBell(),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Body sadržaj
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

/* ----------------------- DRAWER ----------------------- */

class _BookNestDrawer extends StatelessWidget {
  final String currentPage;

  const _BookNestDrawer({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.darkBrown,
      width: MediaQuery.of(context).size.width * 0.72,
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
              title: 'HOME',
              isActive: currentPage == 'HOME',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'HOME') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()),
                  );
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'SHOP',
              isActive: currentPage == 'SHOP',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'SHOP') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ShopScreen()),
                  );
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventsScreen(),
                    ),
                  );
                }
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'ABOUT US',
              isActive: currentPage == 'ABOUT US',
              onTap: () {
                Navigator.pop(context);
                if (currentPage != 'ABOUT US') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                }
              },
            ),
            _DrawerDivider(),

            const Spacer(),

            // MY PROFILE
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                },
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
                      child: Icon(Icons.person_outline,
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

/* ----------------------- NOTIFICATION BELL ----------------------- */

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _service = NotificationService();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _unread = _service.unreadCount;
    _service.addListener(_onNotification);
  }

  void _onNotification(Map<String, dynamic> notification) {
    if (!mounted) return;
    setState(() => _unread = _service.unreadCount);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification['title']}\n${notification['message']}'),
        backgroundColor: AppColors.darkBrown,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _service.removeListener(_onNotification);
    super.dispose();
  }

  void _showNotificationsPanel(BuildContext context) {
    _service.markAllRead();
    setState(() => _unread = 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.pageBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final notifications = _service.notifications;
        if (notifications.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: AppColors.darkBrown),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => Divider(
            color: AppColors.darkBrown.withValues(alpha: 0.2),
          ),
          itemBuilder: (_, i) {
            final n = notifications[i];
            return ListTile(
              leading: Icon(Icons.notifications,
                  color: AppColors.darkBrown, size: 22),
              title: Text(
                n['title'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              subtitle: Text(
                n['message'] ?? '',
                style: TextStyle(
                  color: AppColors.darkBrown.withValues(alpha: 0.75),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNotificationsPanel(context),
      child: Stack(
        children: [
          Icon(Icons.notifications_none,
              color: AppColors.darkBrown, size: 22),
          if (_unread > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}