import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // TODO: Implement actual authentication logic here
        await Future.delayed(const Duration(seconds: 2)); // Simulated delay
        
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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