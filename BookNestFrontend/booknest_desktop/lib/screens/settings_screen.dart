import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLayout(
      pageTitle: 'SETTINGS',
      body: Center(child: Text('Settings')),
    );
  }
}
