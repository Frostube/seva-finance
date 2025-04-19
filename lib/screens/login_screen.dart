import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmailOrUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email or username';
    }
    // If it's an email, validate email format
    if (value.contains('@')) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email';
      }
    }
    // If it's a username, just check minimum length
    else if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting login process with input: ${_emailController.text.trim()}');
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signIn(
        emailOrUsername: _emailController.text.trim(),
        password: _passwordController.text,
      );
      print('DEBUG: Login successful, attempting navigation');

      if (!mounted) return;
      
      print('DEBUG: Context is still mounted, navigating to MainScreen');
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainScreen(),
          settings: const RouteSettings(name: '/main'),
        ),
      );
      print('DEBUG: Navigation completed');
    } on FirebaseAuthException catch (e) {
      print('DEBUG: FirebaseAuthException caught: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = switch (e.code) {
          'user-not-found' => 'No user found with this email or username',
          'wrong-password' => 'Incorrect password',
          'invalid-email' => 'Please enter a valid email',
          'user-disabled' => 'This account has been disabled',
          'too-many-requests' => 'Too many attempts. Please try again later',
          _ => 'An error occurred. Please try again',
        };
      });
    } catch (e) {
      print('DEBUG: Unexpected error during login: $e');
      setState(() {
        _errorMessage = 'An error occurred. Please try again';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paleGreen,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2, top: 5),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 80,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Login Heading
                Text(
                  'Login',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGreen,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 32),

                // Email or Username Field
                CustomTextField(
                  hint: 'Email or Username',
                  controller: _emailController,
                  validator: _validateEmailOrUsername,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.person),
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // Password Field
                CustomTextField(
                  hint: 'Password',
                  controller: _passwordController,
                  validator: _validatePassword,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 32),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.darkGreen.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Login',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB1EC6E),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign Up Link
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: GoogleFonts.inter(
                          color: AppTheme.darkGreen.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.inter(
                              color: AppTheme.darkGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
} 