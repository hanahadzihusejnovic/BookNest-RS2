import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color darkBrown = Color(0xFF443831);
  static const Color lightBrown = Color(0xFFBAB2A7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBrown,
      appBar: AppBar(
        title: const Text(
          'BookNest',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: darkBrown,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.book,
              size: 80,
              color: darkBrown,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to BookNest!',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkBrown,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You are successfully logged in',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                color: darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}