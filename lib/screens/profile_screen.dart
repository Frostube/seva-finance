import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'account_screen.dart';
import 'preferences_screen.dart';
import 'linked_cards_screen.dart';
import 'onboarding_debug_screen.dart';
import 'help_faqs_screen.dart';
import 'debug_coach_screen.dart';
import '../widgets/pro_gate.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Hero(
      tag: 'settings_item_$title',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFF1B4332),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateWithFade(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // App Logo
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SevaFinance',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B4332),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                // Profile Section
                Hero(
                  tag: 'profile_section',
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        // Profile Image
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: const AssetImage(
                              'assets/images/ChatGPT Image 19 abr 2025, 13_33_51.png'),
                          backgroundColor: Colors.grey[200],
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Consumer<UserService>(
                          builder: (context, userService, child) {
                            String displayName = (userService.currentUser?.name ?? '').trim();
                            final firebaseUser = FirebaseAuth.instance.currentUser;
                            if (displayName.isEmpty) {
                              displayName = (firebaseUser?.displayName ?? '').trim();
                            }
                            if (displayName.isEmpty) {
                              final email = (userService.currentUser?.email ?? firebaseUser?.email ?? '').trim();
                              if (email.isNotEmpty) {
                                final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
                                displayName = local.split(' ').map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join(' ');
                              }
                            }
                            if (displayName.isEmpty) displayName = 'User';

                            return Text(
                              _isLoading ? 'Loading...' : displayName,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Consumer<UserService>(
                          builder: (context, userService, child) {
                            final user = userService.currentUser;
                            final firebaseUser =
                                FirebaseAuth.instance.currentUser;
                            final email =
                                user?.email ?? firebaseUser?.email ?? '';

                              return Text(
                                _isLoading ? 'Loading...' : email,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              );
                          },
                        ),
                        const SizedBox(height: 4),
                        const ProBadge(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Settings Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.person_outline,
                        title: 'Account',
                        onTap: () =>
                            _navigateWithFade(context, const AccountScreen()),
                      ),
                      _buildSettingsItem(
                        icon: Icons.credit_card,
                        title: 'Linked Cards',
                        onTap: () => _navigateWithFade(
                            context, const LinkedCardsScreen()),
                      ),
                      _buildSettingsItem(
                        icon: Icons.tune,
                        title: 'Preferences',
                        onTap: () => _navigateWithFade(
                            context, const PreferencesScreen()),
                      ),
                      _buildSettingsItem(
                        icon: Icons.help_outline,
                        title: 'Help & FAQs',
                        onTap: () =>
                            _navigateWithFade(context, const HelpFAQsScreen()),
                      ),
                      _buildSettingsItem(
                        icon: Icons.send_outlined,
                        title: 'Telegram Bot',
                        onTap: () {},
                      ),
                      // Debug options - only show in development
                      if (kDebugMode)
                        _buildSettingsItem(
                          icon: Icons.build_outlined,
                          title: 'Onboarding Debug',
                          onTap: () => _navigateWithFade(
                              context, const OnboardingDebugScreen()),
                        ),
                      if (kDebugMode)
                        _buildSettingsItem(
                          icon: Icons.lightbulb_outline,
                          title: 'Coach Service Debug',
                          onTap: () => _navigateWithFade(
                              context, const DebugCoachScreen()),
                        ),
                    ],
                  ),
                ),

                // Bottom Spacing for Navigation Bar
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
