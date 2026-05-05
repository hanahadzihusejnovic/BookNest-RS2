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
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                    MaterialPageRoute(builder: (context) => const ShopScreen()),
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
                    MaterialPageRoute(builder: (context) => const EventsScreen()),
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

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

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
    _closePanel();
    _service.removeListener(_onNotification);
    super.dispose();
  }

  void _closePanel() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePanel() {
    if (_overlayEntry != null) {
      _closePanel();
      return;
    }

    _service.markAllRead();
    setState(() => _unread = 0);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Tap van panela zatvara ga
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePanel,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          // Panel
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(-240, 28),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.darkBrown,
              child: Container(
                width: 260,
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: AppColors.darkBrown,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _service.notifications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No notifications yet.',
                          style: TextStyle(
                            color: AppColors.pageBg,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _service.notifications.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white,
                          height: 1,
                        ),
                        itemBuilder: (_, i) {
                          final n = _service.notifications[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n['title'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['message'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _togglePanel,
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
      ),
    );
  }
}