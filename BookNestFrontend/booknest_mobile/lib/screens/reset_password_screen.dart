import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../layouts/constants.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _tokenError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  Future<void> _resetPassword() async {
    setState(() {
      _tokenError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;

    if (_tokenController.text.isEmpty) {
      setState(() => _tokenError = 'Token is required');
      hasError = true;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() => _newPasswordError = 'Password is required');
      hasError = true;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      hasError = true;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        _tokenController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );

      if (mounted) {
        AppSnackBar.show(context, 'Password reset successfully!');
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      _showError('Invalid or expired token. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AppSnackBar.show(context, message, isError: true);
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    String? error,
    {bool obscure = false}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: AppColors.darkBrown,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: error != null ? Colors.red : AppColors.darkBrown,
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
          color: error != null ? Colors.red : AppColors.darkBrown,
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
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
                    'Reset password',
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
            const SizedBox(height: 190),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(_tokenController, 'Reset token', _tokenError),
                  const SizedBox(height: 32),
                  _buildField(_newPasswordController, 'New password', _newPasswordError, obscure: true),
                  const SizedBox(height: 32),
                  _buildField(_confirmPasswordController, 'Confirm password', _confirmPasswordError, obscure: true),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
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
                              'RESET PASSWORD',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
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

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}