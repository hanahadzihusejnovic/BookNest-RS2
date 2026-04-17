import 'package:flutter/material.dart';
import '../layouts/app_layout.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLayout(
      pageTitle: 'ORDERS',
      body: Center(child: Text('Orders')),
    );
  }
}
