import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLayout(
      pageTitle: 'EVENTS',
      body: Center(child: Text('Events')),
    );
  }
}
