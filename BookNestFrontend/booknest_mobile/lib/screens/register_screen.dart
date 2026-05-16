import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';
import '../services/city_service.dart';
import '../services/country_service.dart';
import '../services/user_service.dart';
import 'home_screen.dart';
import '../layouts/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _cityService = CityService();
  final _countryService = CountryService();
  final _userService = UserService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 18));
  bool _isLoading = false;

  List<Country> _countries = [];
  List<City> _cities = [];
  List<City> _filteredCities = [];
  Country? _selectedCountry;
  City? _selectedCity;
  File? _selectedImage;

  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _loadCountriesAndCities();
  }

  Future<void> _loadCountriesAndCities() async {
    try {
      final countries = await _countryService.getCountries();
      final cities = await _cityService.getCities();
      if (mounted) {
        setState(() {
          _countries = countries;
          _cities = cities;
        });
      }
    } catch (e) {
      print('❌ Failed to load countries/cities: $e');
    }
  }

  void _onCountryChanged(Country? country) {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _filteredCities = country == null
          ? []
          : _cities.where((c) => c.countryId == country.id).toList();
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedImage = File(result.files.single.path!));
    }
  }

  Future<void> _register() async {
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

    if (_firstNameController.text.isEmpty) {
      setState(() => _firstNameError = 'First name is required');
      hasError = true;
    } else if (_firstNameController.text.length < 2) {
      setState(() => _firstNameError = 'Min 2 characters');
      hasError = true;
    }

    if (_lastNameController.text.isEmpty) {
      setState(() => _lastNameError = 'Last name is required');
      hasError = true;
    } else if (_lastNameController.text.length < 2) {
      setState(() => _lastNameError = 'Min 2 characters');
      hasError = true;
    }

    if (_emailController.text.isEmpty) {
      setState(() => _emailError = 'Email is required');
      hasError = true;
    } else {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(_emailController.text)) {
        setState(() => _emailError = 'Invalid email format');
        hasError = true;
      }
    }

    if (_usernameController.text.isEmpty) {
      setState(() => _usernameError = 'Username is required');
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

    if (_passwordController.text.isEmpty) {
      setState(() => _passwordError = 'Password is required');
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

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Confirm password is required');
      hasError = true;
    } else if (_confirmPasswordController.text != _passwordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (_phoneController.text.isNotEmpty) {
      if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(_phoneController.text)) {
        setState(() => _phoneError = 'Invalid phone format');
        hasError = true;
      } else if (_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
        setState(() => _phoneError = 'Min 9 digits');
        hasError = true;
      }
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      // Korak 1: Registracija
      final request = RegisterRequest(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        emailAddress: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        dateOfBirth: _selectedDate,
        address: _addressController.text.isEmpty ? null : _addressController.text,
        cityId: _selectedCity?.id,
        countryId: _selectedCountry?.id,
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
      );

      await _authService.register(request);

      // Korak 2: Automatski login
      await _authService.login(_usernameController.text, _passwordController.text);

      // Korak 3: Upload slike ako je odabrana
      if (_selectedImage != null) {
        try {
          final imageUrl = await _userService.uploadImage(_selectedImage!);
          await _userService.updateSelf(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            username: _usernameController.text,
            emailAddress: _emailController.text,
            imageUrl: imageUrl,
          );
        } catch (e) {
          print('⚠️ Image upload failed: $e');
        }
      }

      if (mounted) {
        AppSnackBar.show(context, 'Welcome to BookNest!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('🔴 REGISTER ERROR: $e');
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        AppSnackBar.show(context, message, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              primary: AppColors.darkBrown,
              onPrimary: Colors.white,
              surface: AppColors.lightBrown,
              onSurface: AppColors.darkBrown,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBrown,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.darkBrown),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Welcome!',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBrown,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 64),
              child: Text(
                'Create your BookNest account!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkBrown.withValues(alpha: 0.75),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Profile image picker
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.mediumBrown.withValues(alpha: 0.3),
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.person, size: 48, color: AppColors.darkBrown)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.darkBrown,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.lightBrown, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Add profile photo (optional)',
                style: TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _firstNameController,
                    hint: 'First Name',
                    errorText: _firstNameError,
                    onChanged: () { if (_firstNameError != null) setState(() => _firstNameError = null); },
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _lastNameController,
                    hint: 'Last Name',
                    errorText: _lastNameError,
                    onChanged: () { if (_lastNameError != null) setState(() => _lastNameError = null); },
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                    onChanged: () { if (_emailError != null) setState(() => _emailError = null); },
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _usernameController,
                    hint: 'Username',
                    errorText: _usernameError,
                    onChanged: () { if (_usernameError != null) setState(() => _usernameError = null); },
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    obscureText: true,
                    errorText: _passwordError,
                    onChanged: () { if (_passwordError != null) setState(() => _passwordError = null); },
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    obscureText: true,
                    errorText: _confirmPasswordError,
                    onChanged: () { if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null); },
                  ),
                  const SizedBox(height: 32),

                  // Date of Birth
                  GestureDetector(
                    onTap: _selectDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date of Birth: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(color: AppColors.darkBrown, fontSize: 16),
                            ),
                            const Icon(Icons.calendar_today, color: AppColors.darkBrown, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(width: double.infinity, height: 1, color: AppColors.darkBrown),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Text(
                    'Optional Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBrown),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(controller: _addressController, hint: 'Address (optional)'),
                  const SizedBox(height: 32),

                  // Country dropdown
                  _buildDropdown<Country>(
                    hint: 'Country (optional)',
                    value: _selectedCountry,
                    items: _countries,
                    labelFn: (c) => c.name,
                    onChanged: _onCountryChanged,
                  ),
                  const SizedBox(height: 32),

                  // City dropdown
                  _buildDropdown<City>(
                    hint: _selectedCountry == null ? 'Select country first' : 'City (optional)',
                    value: _selectedCity,
                    items: _filteredCities,
                    labelFn: (c) => c.name,
                    onChanged: _selectedCountry == null
                        ? null
                        : (city) => setState(() => _selectedCity = city),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(
                    controller: _phoneController,
                    hint: 'Phone Number (optional)',
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                    onChanged: () { if (_phoneError != null) setState(() => _phoneError = null); },
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkBrown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('REGISTER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(color: AppColors.darkBrown, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Login', style: TextStyle(color: AppColors.darkBrown, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) labelFn,
    required ValueChanged<T?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint,
                style: const TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 16,
                ),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.darkBrown),
              style: const TextStyle(color: AppColors.darkBrown, fontSize: 16),
              dropdownColor: AppColors.lightBrown,
              onChanged: onChanged,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelFn(item)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(width: double.infinity, height: 1, color: AppColors.darkBrown),
      ],
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
            onChanged: (value) { if (onChanged != null) onChanged(); },
            style: const TextStyle(color: AppColors.darkBrown, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: errorText != null ? Colors.red : AppColors.darkBrown, fontSize: 16),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(width: double.infinity, height: 1, color: errorText != null ? Colors.red : AppColors.darkBrown),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(fontSize: 12, color: Colors.red)),
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
    _phoneController.dispose();
    super.dispose();
  }
}