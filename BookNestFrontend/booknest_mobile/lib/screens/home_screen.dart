import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/event.dart';
import '../services/auth_service.dart';
import '../layouts/constants.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  final List<Book> _topBooks = Book.getDummyBooks();
  final List<Event> _events = Event.getDummyEvents();

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final paddingH = 18.0;
    final featured5 = _events.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBg,

      // ✅ SIDEBAR
      drawer: _BookNestDrawer(
        onHome: () {}, // vec si na home
        onShop: () {},
        onEvents: () {},
        onAbout: () {},
        onSettings: () {},
        onProfile: () {},
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopHeader(
                onMenu: () {}, // ovdje vise ne treba, ali ostaje
                onBell: () {
                  // TODO: notifications screen
                },
              ),

              const SizedBox(height: 18),

              // Top picks
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Top 5 picks for you!",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 260,
                      child: GridView.builder(
                        itemCount: _topBooks.take(5).length,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          final book = _topBooks[index];
                          return _BookCard(
                            book: book,
                            onDetails: () {
                              // TODO: go to book details
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Maybe interested
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Maybe you are interested in...",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 185,
                      child: ListView.separated(
                        itemCount: featured5.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = featured5[i];
                          return _InterestRow(
                            title: e.title,
                            subtitle: e.description,
                            timeText:
                                "${_weekday(e.dateTime.weekday)} at ${e.dateTime.hour.toString().padLeft(2, '0')}:${e.dateTime.minute.toString().padLeft(2, '0')}pm",
                            onTap: () {
                              // TODO: event details
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Upcoming events
              _SectionCard(
                child: Column(
                  children: [
                    const Text(
                      "Your upcoming events!",
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 190,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mediumBrown.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: _events.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _UpcomingEventTile(event: _events[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: _SmallButton(
                              text: "See more\nevents",
                              onTap: () {
                                // TODO: navigate to events list
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }

  String _weekday(int w) {
    switch (w) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      default:
        return "Sunday";
    }
  }
}

String _weekday(int w) {
  switch (w) {
    case 1:
      return "Monday";
    case 2:
      return "Tuesday";
    case 3:
      return "Wednesday";
    case 4:
      return "Thursday";
    case 5:
      return "Friday";
    case 6:
      return "Saturday";
    default:
      return "Sunday";
  }
}

/* ----------------------- WIDGETI ----------------------- */

class _TopHeader extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onBell;

  const _TopHeader({
    required this.onMenu,
    required this.onBell,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gornji red: logo + menu
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "BookNest",
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    "World of your stories!",
                    style: TextStyle(
                      color: AppColors.darkBrown,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ MENU OTVARA DRAWER
            Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: Icon(Icons.menu, color: AppColors.darkBrown, size: 26),
                splashRadius: 20,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Donji red: HOME + bell
        Row(
          children: [
            Expanded(
              child: Text(
                "HOME",
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            IconButton(
              onPressed: onBell,
              icon: Icon(Icons.notifications_none,
                  color: AppColors.darkBrown, size: 24),
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mediumBrown,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onDetails;

  const _BookCard({
    required this.book,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pageBg.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.pageBg.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.darkBrown.withOpacity(0.65),
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _SmallButton(
            text: "DETAILS",
            onTap: onDetails,
          ),
        ],
      ),
    );
  }
}

class _InterestRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeText;
  final VoidCallback onTap;

  const _InterestRow({
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pageBg.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Date&Time: $timeText",
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: _SmallButton(
              text: "Click for more\ndetails",
              onTap: onTap,
              height: 38,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  final Event event;
  const _UpcomingEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final day = _weekday(event.dateTime.weekday);
    final hh = event.dateTime.hour.toString().padLeft(2, '0');
    final mm = event.dateTime.minute.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          "Date&Time: $day - $hh:$mm",
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Location: ${event.location}",
          style: const TextStyle(
            color: Color.fromARGB(255, 255, 255, 255),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _weekday(int w) {
    switch (w) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      default:
        return "Sunday";
    }
  }
}

class _SmallButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double height;

  const _SmallButton({
    required this.text,
    required this.onTap,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkBrown.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.pageBg,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
      ),
    );
  }
}

/* ----------------------- DRAWER ----------------------- */

class _BookNestDrawer extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onShop;
  final VoidCallback onEvents;
  final VoidCallback onAbout;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  const _BookNestDrawer({
    required this.onHome,
    required this.onShop,
    required this.onEvents,
    required this.onAbout,
    required this.onSettings,
    required this.onProfile,
  });

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
                    "BookNest",
                    style: TextStyle(
                      color: AppColors.pageBg,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 0),
                  Text(
                    "World of your stories!",
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

            _DrawerItem(title: "HOME", onTap: onHome),
            _DrawerDivider(),
            _DrawerItem(title: "SHOP", onTap: onShop),
            _DrawerDivider(),
            _DrawerItem(title: "EVENTS", onTap: onEvents),
            _DrawerDivider(),
            _DrawerItem(title: "ABOUT US", onTap: onAbout),
            _DrawerDivider(),
            _DrawerItem(title: "SETTINGS", onTap: onSettings),
            _DrawerDivider(),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onProfile();
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
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.pageBg,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "MY PROFILE",
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
  final VoidCallback onTap;

  const _DrawerItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          title,
          style: TextStyle(
            color: AppColors.pageBg,
            fontSize: 20,
            fontWeight: FontWeight.w300,
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