import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLayout(
      pageTitle: 'RESERVATIONS',
      body: Center(child: Text('Reservations')),
    );
  }
}
