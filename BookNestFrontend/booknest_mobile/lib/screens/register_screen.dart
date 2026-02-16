import 'package:flutter/material.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 18));
  bool _isLoading = false;

  // Error states - ISTO KAO LOGIN
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneError;

  // Tvoje boje iz Figme
  static const Color darkBrown = Color(0xFF443831);
  static const Color mediumBrown = Color(0xFF776860);
  static const Color lightBrown = Color(0xFFBAB2A7);

  Future<void> _register() async {
    // Reset all errors
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _usernameError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _phoneError = null;
    });

    bool hasError = false;

    // First Name validation
    if (_firstNameController.text.isEmpty) {
      setState(() => _firstNameError = 'Required');
      hasError = true;
    } else if (_firstNameController.text.length < 2) {
      setState(() => _firstNameError = 'Min 2 characters');
      hasError = true;
    }

    // Last Name validation
    if (_lastNameController.text.isEmpty) {
      setState(() => _lastNameError = 'Required');
      hasError = true;
    } else if (_lastNameController.text.length < 2) {
      setState(() => _lastNameError = 'Min 2 characters');
      hasError = true;
    }

    // Email validation
    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Required');
      hasError = true;
    } else {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(_emailController.text)) {
        setState(() => _emailError = 'Invalid email format');
        hasError = true;
      }
    }

    // Username validation
    if (_usernameController.text.isEmpty) {
      setState(() => _usernameError = 'Required');
      hasError = true;
    } else if (_usernameController.text.length < 4) {
      setState(() => _usernameError = 'Min 4 characters');
      hasError = true;
    } else if (_usernameController.text.length > 20) {
      setState(() => _usernameError = 'Max 20 characters');
      hasError = true;
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(_usernameController.text)) {
      setState(() => _usernameError = 'Only letters, numbers and _');
      hasError = true;
    }

    // Password validation
    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Required');
      hasError = true;
    } else if (_passwordController.text.length < 8) {
      setState(() => _passwordError = 'Min 8 characters');
      hasError = true;
    } else if (!_passwordController.text.contains(RegExp(r'[A-Z]'))) {
      setState(() => _passwordError = 'Need uppercase letter');
      hasError = true;
    } else if (!_passwordController.text.contains(RegExp(r'[a-z]'))) {
      setState(() => _passwordError = 'Need lowercase letter');
      hasError = true;
    } else if (!_passwordController.text.contains(RegExp(r'[0-9]'))) {
      setState(() => _passwordError = 'Need number');
      hasError = true;
    }

    // Confirm Password validation
    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Required');
      hasError = true;
    } else if (_confirmPasswordController.text != _passwordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    // Phone validation (optional)
    if (_phoneController.text.isNotEmpty) {
      if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(_phoneController.text)) {
        setState(() => _phoneError = 'Invalid phone format');
        hasError = true;
      } else if (_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
        setState(() => _phoneError = 'Min 9 digits');
        hasError = true;
      }
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🟢 REGISTER SCREEN: Starting registration...');
      
      final request = RegisterRequest(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        emailAddress: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        dateOfBirth: _selectedDate,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        country: _countryController.text.isEmpty ? null : _countryController.text,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        roleIds: [3],
      );

      await _authService.register(request);
      
      print('🟢 REGISTER SCREEN: Registration successful!');

      if (mounted) {
        _showSuccess('Registration successful! Please login.');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        });
      }
    } catch (e) {
      print('🔴 REGISTER SCREEN ERROR: $e');
      _showError('Registration failed');
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: darkBrown,
              onPrimary: Colors.white,
              surface: lightBrown,
              onSurface: darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBrown,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: darkBrown),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              
              const SizedBox(height: 20),

              // Title
              const Text(
                'Register',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 40),

              // First Name
              _buildTextField(
                controller: _firstNameController,
                hint: 'First Name',
                errorText: _firstNameError,
                onChanged: () {
                  if (_firstNameError != null) {
                    setState(() => _firstNameError = null);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Last Name
              _buildTextField(
                controller: _lastNameController,
                hint: 'Last Name',
                errorText: _lastNameError,
                onChanged: () {
                  if (_lastNameError != null) {
                    setState(() => _lastNameError = null);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Email
              _buildTextField(
                controller: _emailController,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: () {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Username
              _buildTextField(
                controller: _usernameController,
                hint: 'Username',
                errorText: _usernameError,
                onChanged: () {
                  if (_usernameError != null) {
                    setState(() => _usernameError = null);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Password
              _buildTextField(
                controller: _passwordController,
                hint: 'Password',
                obscureText: true,
                errorText: _passwordError,
                onChanged: () {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Confirm Password
              _buildTextField(
                controller: _confirmPasswordController,
                hint: 'Confirm Password',
                obscureText: true,
                errorText: _confirmPasswordError,
                onChanged: () {
                  if (_confirmPasswordError != null) {
                    setState(() => _confirmPasswordError = null);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Date of Birth
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _selectDate,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date of Birth: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: darkBrown,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: darkBrown, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: darkBrown,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Optional fields header
              const Text(
                'Optional Information',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                ),
              ),
              const SizedBox(height: 24),

              // Address
              _buildTextField(
                controller: _addressController,
                hint: 'Address (optional)',
              ),
              const SizedBox(height: 32),

              // City
              _buildTextField(
                controller: _cityController,
                hint: 'City (optional)',
              ),
              const SizedBox(height: 32),

              // Country
              _buildTextField(
                controller: _countryController,
                hint: 'Country (optional)',
              ),
              const SizedBox(height: 32),

              // Phone
              _buildTextField(
                controller: _phoneController,
                hint: 'Phone Number (optional)',
                keyboardType: TextInputType.phone,
                errorText: _phoneError,
                onChanged: () {
                  if (_phoneError != null) {
                    setState(() => _phoneError = null);
                  }
                },
              ),
              const SizedBox(height: 40),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBrown,
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
                          'REGISTER',
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

              // Login link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: darkBrown,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          color: darkBrown,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? errorText,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: (value) {
              if (onChanged != null) {
                onChanged();
              }
            },
            style: const TextStyle(
              fontFamily: 'Roboto',
              color: darkBrown,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Roboto',
                color: errorText != null 
                    ? Colors.red
                    : darkBrown,
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
          color: errorText != null ? Colors.red : darkBrown,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}