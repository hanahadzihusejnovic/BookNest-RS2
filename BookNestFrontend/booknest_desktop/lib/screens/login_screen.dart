import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../layouts/constants.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _rememberMe = false;
  String? _usernameError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _checkRememberMe();
  }

  Future<void> _checkRememberMe() async {
    final credentials = await _authService.getSavedCredentials();
    if (credentials != null) {
      setState(() {
        _usernameController.text = credentials['username']!;
        _passwordController.text = credentials['password']!;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _usernameError = null;
      _passwordError = null;
    });

    bool hasError = false;

    if (_usernameController.text.isEmpty) {
      setState(() => _usernameError = 'Username is required');
      hasError = true;
    }

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!response.roles.contains('Admin')) {
        await _authService.logout();
        setState(() {
          _usernameController.clear();
          _passwordController.clear();
          _rememberMe = false;
        });
        if (mounted) {
          AppSnackBar.show(context, 'Access denied. Admin accounts only.', isError: true);
        }
        setState(() => _isLoading = false);
        return;
      }

      if (_rememberMe) {
        await _authService.saveRememberMe(
          _usernameController.text,
          _passwordController.text,
        );
      } else {
        await _authService.clearRememberMe();
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Invalid username or password', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      body: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Log into your BookNest admin account.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkBrown.withValues(alpha: 0.75),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 48),

                // Username field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      child: TextField(
                        controller: _usernameController,
                        onChanged: (value) {
                          if (_usernameError != null) {
                            setState(() => _usernameError = null);
                          }
                        },
                        style: const TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle: TextStyle(
                            color: _usernameError != null
                                ? Colors.red
                                : AppColors.darkBrown,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: _usernameError != null ? Colors.red : AppColors.darkBrown,
                    ),
                    if (_usernameError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _usernameError!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                // Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        onChanged: (value) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        style: const TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: _passwordError != null
                                ? Colors.red
                                : AppColors.darkBrown,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: _passwordError != null ? Colors.red : AppColors.darkBrown,
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _passwordError!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // Remember me & Forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _rememberMe ? AppColors.darkBrown : AppColors.lightBrown,
                              border: Border.all(color: AppColors.darkBrown, width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: _rememberMe
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: const Text(
                            'Remember me',
                            style: TextStyle(fontSize: 14, color: AppColors.darkBrown),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkBrown,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBrown,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
