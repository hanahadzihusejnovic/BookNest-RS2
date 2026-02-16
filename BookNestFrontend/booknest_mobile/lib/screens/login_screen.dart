import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

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

  // Tvoje boje iz Figme
  static const Color darkBrown = Color(0xFF443831);
  static const Color mediumBrown = Color(0xFF776860);
  static const Color lightBrown = Color(0xFFBAB2A7);

  Future<void> _login() async {
  if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
    _showError('Please enter username and password');
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
    print('🟢 LOGIN SCREEN: Token received: ${response.token.substring(0, 20)}...');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  } catch (e) {
    print('🔴 LOGIN SCREEN ERROR: $e');
    print('🔴 LOGIN SCREEN ERROR TYPE: ${e.runtimeType}');
    _showError('Login failed');
  } finally {
    setState(() {
      _isLoading = false;
    });
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
      backgroundColor: lightBrown,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SAMO "Welcome back!" tekst - lijevi gornji ugao
          const SizedBox(height: 26),
          
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: SizedBox(
              width: 241,
              height: 116,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Welcome',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'back!',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: darkBrown,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 50),

          // Login Card - 377x537
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Container(
              width: 357,
              height: 500,
              decoration: BoxDecoration(
                color: mediumBrown, 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // LOGIN tekst
                  Positioned(
                    top: 46,
                    left: (357 - 103) / 2,
                    child: const SizedBox(
                      width: 103,
                      height: 40,
                      child: Center(
                        child: Text(
                          'LOGIN',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Username input field
                  Positioned(
                    top: 147,
                    left: 19,
                    child: SizedBox(
                      width: 310,
                      height: 20,
                      child: TextField(
                        controller: _usernameController,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Username',  // ← DODAJ OVO
                          hintStyle: TextStyle(  // ← I OVO
                            fontFamily: 'Roboto',
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Password input field
                  Positioned(
                    top: 228,
                    left: 19,
                    child: SizedBox(
                      width: 310,
                      height: 20,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Password',  // ← DODAJ OVO
                          hintStyle: TextStyle(  // ← I OVO
                            fontFamily: 'Roboto',
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Prva linija
                  Positioned(
                    top: 180,
                    left: 19,
                    child: Container(
                      width: 310,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Druga linija
                  Positioned(
                    top: 261,
                    left: 19,
                    child: Container(
                      width: 310,
                      height: 1,
                      color: Colors.white,
                    ),
                  ),
                  
                  // Remember me checkbox - 15x15
                  Positioned(
                    top: 280,
                    left: 19,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: _rememberMe ? Colors.white : mediumBrown,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check,
                                size: 10,
                                color: mediumBrown,
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Remember me tekst - 104x21
                  Positioned(
                    top: 280,
                    left: 42,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: const SizedBox(
                        width: 104,
                        height: 21,
                        child: Text(
                          'Remember me',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Forgot your password - 159x21
                  Positioned(
                    top: 280,
                    left: 189,
                    child: GestureDetector(
                      onTap: () {
                        
                      },
                      child: const SizedBox(
                        width: 159,
                        height: 21,
                        child: Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                  // Login button - 113x53
                  Positioned(
                    top: 365,
                    left: 115,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _login,
                      child: Container(
                        width: 113,
                        height: 53,
                        decoration: BoxDecoration(
                          color: darkBrown,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),

                  // Don't have an account? Sign up
                  Positioned(
                    top: 435,
                    left: 69,
                    child: Row(
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
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
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
        ],
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