import 'package:flutter/material.dart';
import '../layouts/constants.dart';
import '../screens/home_screen.dart';
import '../screens/shop_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/tbr_screen.dart';
import '../screens/profile_screen.dart';

class AppLayout extends StatelessWidget {
  final String pageTitle;
  final Widget body;
  final bool showCartFavTbr;
  final bool showBackButton;
  final bool showPageActionsRow;

  const AppLayout({
    super.key,
    required this.pageTitle,
    required this.body,
    this.showCartFavTbr = true,
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
                        builder: (ctx) => IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: Icon(Icons.menu,
                              color: AppColors.darkBrown, size: 26),
                          splashRadius: 20,
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
                      if (showCartFavTbr) ...[
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CartScreen()),
                            );
                          },
                          child: Icon(Icons.shopping_cart_outlined,
                              color: AppColors.darkBrown, size: 22),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const FavoritesScreen()),
                            );
                          },
                          child: Icon(Icons.favorite_border,
                              color: AppColors.darkBrown, size: 22),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const TBRScreen()),
                            );
                          },
                          child: Icon(Icons.bookmark_border,
                              color: AppColors.darkBrown, size: 22),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: () {},
                          child: Icon(Icons.notifications_none,
                              color: AppColors.darkBrown, size: 22),
                        ),
                      ],
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
                      color: AppColors.pageBg.withOpacity(0.85),
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
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'ABOUT US',
              isActive: currentPage == 'ABOUT US',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _DrawerDivider(),
            _DrawerItem(
              title: 'SETTINGS',
              isActive: currentPage == 'SETTINGS',
              onTap: () {
                Navigator.pop(context);
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
            color: isActive ? AppColors.lightBrown : AppColors.pageBg,
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
        color: AppColors.pageBg.withOpacity(0.35),
        thickness: 1,
        height: 1,
      ),
    );
  }
}