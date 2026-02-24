import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'two_fa_page.dart';
import 'package:my_app/main.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;
  bool _isSubmitting = false;
  DateTime? _cooldownUntil;

  static const Duration _cooldownDuration = Duration(seconds: 30);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\\[\]~`]').hasMatch(password);
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final now = DateTime.now();

    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      final remaining = _cooldownUntil!.difference(now).inSeconds;
      _showMessage('Please wait $remaining seconds before trying again.');
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (!_emailRegex.hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    if (!_isStrongPassword(password)) {
      _showMessage('Use at least 8 characters with uppercase, lowercase, numbers, and symbols.');
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
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.sendEmailVerification();

      _showMessage('Check your email to confirm your account.');
    } on FirebaseAuthException catch (error) {
      if (error.code == 'too-many-requests') {
        _cooldownUntil = DateTime.now().add(_cooldownDuration);
        _showMessage(
          'Too many requests. Please wait a bit before trying again.',
        );
      } else {
        _showMessage('Registration failed. Please verify details and try again.');
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

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: "TheftSense")),
      );
    } on FirebaseAuthException {
      if (mounted) {
        _showMessage('Google sign up failed. Please try again.');
      }
    } catch (error) {
      // Don't show error if user simply cancelled
      final errorMsg = error.toString().toLowerCase();
      if (!errorMsg.contains('cancel') && 
          !errorMsg.contains('user_canceled') && 
          !errorMsg.contains('popup_closed') &&
          mounted) {
        _showMessage('Google sign up failed. Please try again.');
      }
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
              ),
              onPressed: _isSubmitting ? null : _register,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign Up'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              onPressed: _isSubmitting ? null : _signUpWithGoogle,
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.g_mobiledata, size: 24);
                },
              ),
              label: const Text('Sign up with Google'),
            ),
          ],
        ),
      ),
    );
  }
}
