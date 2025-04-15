import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Controls the fade-in animation (true = visible, false = invisible)
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Triggers the fade-in animation after screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive layout calculations
    final screenSize = MediaQuery.of(context).size;
    // Breakpoint for smaller screens - adjust 700 to change when the UI adapts
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      // Main background color - edit in AppTheme.paleGreen
      backgroundColor: AppTheme.paleGreen,
      body: SafeArea(
        child: Stack(
          children: [
            // Logo positioned in top-left
            Positioned(
              left: 2,
              top: 5,
              child: Image.asset(
                'assets/images/logo.png',
                height: 140,
              ),
            ),
            // Main content with padding
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                // Animation duration - adjust for faster/slower fade-in
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeIn,
                opacity: _visible ? 1.0 : 0.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spacer to account for logo height
                    const SizedBox(height: 140),
                    
                    const Spacer(flex: 3),
                    
                    // Main headline text
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Track Your\n'),
                          TextSpan(
                            text: 'Spending\n',
                            style: TextStyle(
                              // Emphasized text color - edit in AppTheme.darkerGreen
                              color: AppTheme.darkerGreen,
                              // Font weight for emphasis - adjust w600 as needed
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: 'Effortlessly'),
                        ],
                      ),
                      style: GoogleFonts.inter(
                        // Responsive font sizes - adjust these numbers for larger/smaller text
                        fontSize: isSmallScreen ? 42 : 48,
                        // Headline font weight - adjust w500 for bolder/lighter text
                        fontWeight: FontWeight.w500,
                        // Main text color - edit in AppTheme.darkGreen
                        color: AppTheme.darkGreen,
                        // Line height - adjust 1.1 for more/less space between lines
                        height: 1.1,
                        // Letter spacing - adjust -0.5 to change space between letters
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Space between headline and subtitle - adjust 12 to increase/decrease gap
                    const SizedBox(height: 12),
                    // Subtitle text
                    Text(
                      'Manage your finances easily using our intuitive and user-friendly interface and set financial goals and monitor your progress',
                      style: GoogleFonts.inter(
                        // Responsive subtitle sizes - adjust for larger/smaller text
                        fontSize: isSmallScreen ? 15 : 16,
                        // Subtitle color with opacity - adjust 0.8 for more/less transparency
                        color: AppTheme.darkGreen.withOpacity(0.8),
                        // Line height - adjust 1.5 for more/less space between lines
                        height: 1.5,
                        // Subtitle font weight - adjust w400 for bolder/lighter text
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    // Space before buttons - adjust flex: 2 to change spacing
                    const Spacer(flex: 2),
                    
                    // Main CTA button - styling defined in AppTheme
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text('Get Started'),
                    ),
                    // Space between buttons - adjust for more/less gap
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // "Already have an account?" text
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.inter(
                            // Secondary text color - adjust opacity (0.8) for visibility
                            color: AppTheme.darkGreen.withOpacity(0.8),
                            // Responsive font size - adjust these numbers as needed
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                        // Login link
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: GoogleFonts.inter(
                              // Login link color - edit in AppTheme.darkGreen
                              color: AppTheme.darkGreen,
                              // Responsive font size - adjust these numbers as needed
                              fontSize: isSmallScreen ? 13 : 14,
                              // Login text weight - adjust w500 for bolder/lighter
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Bottom spacing - adjust numbers for more/less space
                    SizedBox(height: isSmallScreen ? 20 : 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 