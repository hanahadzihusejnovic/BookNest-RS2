import 'package:flutter/material.dart';
//import 'login_screen.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const Color darkBrown = Color(0xFF443831);
  static const Color mediumBrown = Color(0xFF776860);
  static const Color lightBrown = Color(0xFFBAB2A7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBrown,
      appBar: AppBar(
        title: const Text(
          'Register',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Colors.white,
          ),
        ),
        backgroundColor: darkBrown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: mediumBrown,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'REGISTER',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Registration coming soon...',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}