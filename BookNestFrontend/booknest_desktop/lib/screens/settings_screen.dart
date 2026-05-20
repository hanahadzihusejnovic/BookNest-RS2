import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';
import 'dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      pageTitle: 'SETTINGS',
      onBack: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
      body: const Center(child: Text('Settings')),
    );
  }
}
