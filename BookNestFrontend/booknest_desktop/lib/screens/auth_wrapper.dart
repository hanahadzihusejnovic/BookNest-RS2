import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  late final Future<bool> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _authService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
