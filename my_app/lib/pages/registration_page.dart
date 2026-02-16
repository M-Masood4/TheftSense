import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'forgot_password_page.dart';
import 'two_fa_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;
  bool _isSubmitting = false;
  DateTime? _cooldownUntil;

  static const Duration _cooldownDuration = Duration(seconds: 30);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
    );
  }

  void _goToTwoFa() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TwoFaPage()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final now = DateTime.now();

    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      final remaining = _cooldownUntil!.difference(now).inSeconds;
      _showMessage('Please wait $remaining seconds before trying again.');
      return;
    }

    if (email.isEmpty || username.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        },
      );

      _showMessage(
        response.user == null
            ? 'Check your email to confirm your account.'
            : 'Account created successfully.',
      );
    } on AuthException catch (error) {
      final statusCode = error.statusCode ?? 0;
      if (statusCode == 429) {
        _cooldownUntil = DateTime.now().add(_cooldownDuration);
        _showMessage(
          'Too many requests. Please wait a bit before trying again.',
        );
      } else {
        _showMessage(error.message);
      }
    } catch (error) {
      _showMessage('Registration failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLabeledField({
    required String label,
    required Widget field,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  InputDecoration _fieldDecoration({required String hint}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      filled: true,
      isDense: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabeledField(
              label: 'Email',
              field: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration(hint: ''),
              ),
            ),
            const SizedBox(height: 18),
            _buildLabeledField(
              label: 'Username',
              field: TextField(
                controller: _usernameController,
                decoration: _fieldDecoration(hint: ''),
              ),
            ),
            const SizedBox(height: 18),
            _buildLabeledField(
              label: 'Password',
              field: TextField(
                controller: _passwordController,
                obscureText: _passwordObscured,
                decoration: _fieldDecoration(hint: '').copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _passwordObscured = !_passwordObscured;
                      });
                    },
                    icon: Icon(
                      _passwordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildLabeledField(
              label: 'Confirm Password',
              field: TextField(
                controller: _confirmPasswordController,
                obscureText: _confirmPasswordObscured,
                decoration: _fieldDecoration(hint: '').copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _confirmPasswordObscured = !_confirmPasswordObscured;
                      });
                    },
                    icon: Icon(
                      _confirmPasswordObscured
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _goToForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _register,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
