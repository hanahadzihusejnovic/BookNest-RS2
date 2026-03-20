import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../layouts/constants.dart';
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
    _checkRememberMe(); // ← DODANO: Učitaj sačuvane credentials
  }

  // ← DODANO: Provjeri i učitaj Remember Me podatke
  Future<void> _checkRememberMe() async {
    print('🔵 LOGIN: Checking Remember Me...');
    
    final credentials = await _authService.getSavedCredentials();
    
    if (credentials != null) {
      print('✅ LOGIN: Found saved credentials for: ${credentials['username']}');
      
      setState(() {
        _usernameController.text = credentials['username']!;
        _passwordController.text = credentials['password']!;
        _rememberMe = true;
      });
    } else {
      print('⚠️ LOGIN: No saved credentials found');
    }
  }

  Future<void> _login() async {
  // Reset errors
  setState(() {
    _usernameError = null;
    _passwordError = null;
  });

  // Validacija
  bool hasError = false;
  
  if (_usernameController.text.isEmpty) {
    setState(() {
      _usernameError = 'Username is required';
    });
    hasError = true;
  }
  
  if (_passwordController.text.isEmpty) {
    setState(() {
      _passwordError = 'Password is required';
    });
    hasError = true;
  }

  if (hasError) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    print('🟢 LOGIN SCREEN: Starting login...');
    print('🟢 LOGIN SCREEN: Username: ${_usernameController.text}');
    
    final response = await _authService.login(
      _usernameController.text,
      _passwordController.text,
    );
    
    print('🟢 LOGIN SCREEN: Login successful!');
    print('🟢 LOGIN SCREEN: User roles: ${response.roles}');

    // ← PROVJERI ROLU - BLOKIRAJ ADMIN:
    if (response.roles.contains('Admin')) {
      print('❌ LOGIN SCREEN: Admin account detected - Access denied!');
      
      // Logout immediately
      await _authService.logout();
      
      setState(() {
        _usernameController.clear();
        _passwordController.clear();
        _rememberMe = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Admin accounts cannot access the mobile app.\nPlease use the admin web portal.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      setState(() => _isLoading = false);
      return; // ZAUSTAVI login proces
    }

    // PROVJERI DA LI IMA USER ROLU:
    if (!response.roles.contains('User')) {
      print('❌ LOGIN SCREEN: Invalid account type');
      
      await _authService.logout();
      
      setState(() {
        _usernameController.clear();
        _passwordController.clear();
        _rememberMe = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid account type. Please contact support.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
      setState(() => _isLoading = false);
      return;
    }

    print('✅ LOGIN SCREEN: User role validated - Access granted!');

    // Remember Me logic
    if (_rememberMe) {
      print('💾 LOGIN: Saving Remember Me credentials...');
      await _authService.saveRememberMe(
        _usernameController.text,
        _passwordController.text,
      );
    } else {
      print('🗑️ LOGIN: Clearing Remember Me credentials...');
      await _authService.clearRememberMe();
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  } catch (e) {
    print('🔴 LOGIN SCREEN ERROR: $e');
    _showError('Invalid username or password');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Welcome back!
              const Text(
                'Welcome back!',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log into your BookNest account!',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkBrown.withOpacity(0.75),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 180),

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
                          setState(() {
                            _usernameError = null;
                          });
                        }
                      },
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: AppColors.darkBrown,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Username',
                        hintStyle: TextStyle(
                          fontFamily: 'Roboto',
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
                    color: _usernameError != null ? Colors.red :AppColors.darkBrown,
                  ),
                  if (_usernameError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _usernameError!,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.red,
                      ),
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
                          setState(() {
                            _passwordError = null;
                          });
                        }
                      },
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: AppColors.darkBrown,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          fontFamily: 'Roboto',
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
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Remember me & Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember me
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                          print('🔘 Remember Me: $_rememberMe'); // ← DODANO: Debug log
                        },
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _rememberMe ? AppColors.darkBrown : AppColors.lightBrown,
                            border: Border.all(color: AppColors.darkBrown, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _rememberMe
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                          print('🔘 Remember Me: $_rememberMe'); // ← DODANO: Debug log
                        },
                        child: const Text(
                          'Remember me',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: AppColors.darkBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Forgot password
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
                        fontFamily: 'Roboto',
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
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Sign up link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
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