import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../layouts/constants.dart';
import '../layouts/app_layout.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _isLoadingPrefs = false;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.pageBg,
        title: Text(
          'Delete account',
          style: TextStyle(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: Text(
          'Are you sure you want to delete your account? '
          'This action cannot be undone and all your data will be permanently removed.',
          style: TextStyle(
            color: AppColors.darkBrown.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.darkBrown)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await UserService().deleteSelf();
      await AuthService().logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'SETTINGS',
      showBackButton: true,
      body: _isLoadingPrefs
          ? Center(
              child: CircularProgressIndicator(color: AppColors.darkBrown))
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications
                  _SectionLabel('Preferences'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    child: Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: AppColors.darkBrown, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: AppColors.darkBrown,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Receive app notifications',
                                style: TextStyle(
                                  color: AppColors.darkBrown
                                      .withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: _toggleNotifications,
                          activeThumbColor: AppColors.darkBrown,
                          activeTrackColor: AppColors.mediumBrown,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Account
                  _SectionLabel('Account'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    child: _SettingsTile(
                      icon: Icons.person_outline,
                      label: 'My Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfileScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  _SettingsCard(
                    child: _SettingsTile(
                      icon: Icons.delete_outline,
                      label: 'Delete account',
                      isDestructive: true,
                      onTap: _showDeleteAccountDialog,
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

/* ----------------------- WIDGETS ----------------------- */

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.darkBrown,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBrown.withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade700 : AppColors.darkBrown;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }
}
