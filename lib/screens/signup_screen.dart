import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'dart:async';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Please enter a valid email';
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        print('Starting signup process...'); // Debug log
        
        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
        
        print('Signup successful!'); // Debug log
        
        if (!mounted) return;
        
        // Even if Firestore profile creation fails, we can still proceed to the main screen
        // The profile will be created when the connection is better
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } catch (e) {
        print('Signup error: $e'); // Debug log
        
        if (!mounted) return;
        
        String errorMessage = 'An error occurred';
        if (e is FirebaseAuthException) {
          print('Firebase Auth Error Code: ${e.code}'); // Debug log
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'An account already exists with this email';
              break;
            case 'invalid-email':
              errorMessage = 'Invalid email address';
              break;
            case 'weak-password':
              errorMessage = 'Password is too weak';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Email/password accounts are not enabled';
              break;
            default:
              errorMessage = e.message ?? 'An error occurred during signup';
              break;
          }
        } else if (e is TimeoutException) {
          errorMessage = 'Connection timeout. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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

                // Sign Up Heading
                Text(
                  'Sign Up',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB1EC6E),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 32),

                // Name Field
                CustomTextField(
                  hint: 'Full Name',
                  controller: _nameController,
                  validator: _validateName,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(Icons.person_outline),
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 16),

                // Email Field
                CustomTextField(
                  hint: 'Email',
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
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

                const SizedBox(height: 16),

                // Confirm Password Field
                CustomTextField(
                  hint: 'Confirm Password',
                  controller: _confirmPasswordController,
                  validator: _validateConfirmPassword,
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  enabled: !_isLoading,
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
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
                            'Sign Up',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB1EC6E),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Login Link
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an account? ',
                        style: GoogleFonts.inter(
                          color: AppTheme.darkGreen.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
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