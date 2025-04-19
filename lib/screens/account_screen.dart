import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'personal_details_screen.dart';
import 'change_password_screen.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  bool _isTwoFactorEnabled = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Map<String, dynamic>? _userData;
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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF1B4332),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                
                // Personal Details Section
                _buildSectionTitle('Personal Details', CupertinoIcons.person_crop_circle),
                const SizedBox(height: 16),
                Hero(
                  tag: 'personal_details_card',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const PersonalDetailsScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          ).then((_) => _loadUserData()); // Reload data when returning from PersonalDetailsScreen
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B4332).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.person_fill,
                                color: Color(0xFF1B4332),
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userData?['name'] ?? 'No name set',
                                        style: GoogleFonts.inter(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? 'No email set',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userData?['phone'] ?? 'No phone set',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Security Section
                _buildSectionTitle('Security', CupertinoIcons.shield_fill),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const ChangePasswordScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 300),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Change Password',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 20,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Two-Factor Authentication',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            CupertinoSwitch(
                              value: _isTwoFactorEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _isTwoFactorEnabled = value;
                                });
                              },
                              activeTrackColor: const Color(0xFF1B4332),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Account Actions Section
                _buildSectionTitle('Account Actions', CupertinoIcons.gear_alt_fill),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _showDeleteConfirmation(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                'Delete Account',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 1, color: Colors.grey[200]),
                      InkWell(
                        onTap: () => _showLogOutConfirmation(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                'Log Out',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    print('DEBUG: Showing delete confirmation dialog');
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Account',
            style: GoogleFonts.inter(
              color: AppTheme.darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
            style: GoogleFonts.inter(
              color: AppTheme.darkGreen.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('DEBUG: User cancelled account deletion');
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppTheme.darkGreen,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                print('DEBUG: User confirmed account deletion');
                // Close the dialog first
                Navigator.of(context).pop();
                
                final authService = Provider.of<AuthService>(context, listen: false);
                print('DEBUG: Starting account deletion process');
                print('DEBUG: Current user: ${authService.user?.email}');
                
                try {
                  // Delete the account first while we still have a valid context
                  print('DEBUG: Calling authService.deleteAccount()');
                  await authService.deleteAccount();
                  print('DEBUG: Account deletion successful');
                  
                  // Show success message
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account deleted successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    
                    // Navigate to welcome screen after showing the success message
                    print('DEBUG: Navigating to welcome screen after successful deletion');
                    await Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const WelcomeScreen(),
                        settings: const RouteSettings(name: '/welcome'),
                      ),
                      (route) => false,
                    );
                  }
                  
                } catch (e) {
                  print('DEBUG: Error during account deletion: $e');
                  if (e is FirebaseAuthException) {
                    print('DEBUG: Firebase Auth Error Code: ${e.code}');
                    print('DEBUG: Firebase Auth Error Message: ${e.message}');
                  }
                  
                  if (context.mounted) {
                    String errorMessage;
                    if (e is FirebaseAuthException) {
                      if (e.code == 'requires-recent-login') {
                        errorMessage = 'Please log out and log in again before deleting your account';
                      } else {
                        errorMessage = e.message ?? 'Failed to delete account';
                      }
                    } else {
                      errorMessage = 'Failed to delete account. Please try again.';
                    }
                    
                    print('DEBUG: Showing error message: $errorMessage');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogOutConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Log Out',
            style: GoogleFonts.inter(
              color: AppTheme.darkGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.inter(
              color: AppTheme.darkGreen.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppTheme.darkGreen,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  print('DEBUG: Starting sign out process');
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.signOut();
                  print('DEBUG: Sign out successful');
                  
                  if (!context.mounted) return;
                  
                  // Navigate to welcome screen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  print('DEBUG: Error during sign out: $e');
                  if (!context.mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to sign out. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(
                'Log Out',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 