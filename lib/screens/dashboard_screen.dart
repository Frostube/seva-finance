import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'expenses_screen.dart';
import 'linked_cards_screen.dart';
import 'notifications_screen.dart';
import 'recent_activity_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onNavigate;
  
  const DashboardScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with greeting and notification
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hi, Jonathan',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Welcome Back!',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppTheme.darkGreen.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                color: AppTheme.darkGreen,
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationsScreen(),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Wallet Balance Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Wallets',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.darkGreen.withOpacity(0.7),
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.darkGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () => _navigateWithFade(context),
                          ),
                        ],
                      ),
                    ),

                    // Balance and Cards Section
                    SizedBox(
                      height: 200,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16.0,
                        ),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCard(
                            '\$17,298.92',
                            'Main Wallet',
                            AppTheme.darkGreen,
                          ),
                          const SizedBox(width: 16),
                          _buildCard(
                            '\$3,421.63',
                            'Groceries',
                            const Color(0xFF1E1E1E),
                          ),
                          const SizedBox(width: 16),
                          _buildAddCard(context),
                        ],
                      ),
                    ),

                    // Quick Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(CupertinoIcons.arrow_up, size: 20),
                              label: const Text('Send'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.paleGreen,
                                foregroundColor: AppTheme.darkGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(CupertinoIcons.arrow_down, size: 20),
                              label: const Text('Request'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.darkGreen.withOpacity(0.1),
                              ),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.grid_view_rounded,
                                color: AppTheme.darkGreen,
                              ),
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recent Activity
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Activity',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RecentActivityScreen(),
                                  ),
                                ),
                                icon: const Text('See Details'),
                                label: const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.darkGreen,
                                  textStyle: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionItem(
                            'Dribbble',
                            'Today, 16:32',
                            '-\$120',
                            'Transfer',
                            Colors.pink,
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionItem(
                            'Wilson Mango',
                            'Today, 10:12',
                            '-\$240',
                            'Transfer',
                            Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          _buildTransactionItem(
                            'Abram Botosh',
                            'Yesterday',
                            '+\$450',
                            'Income',
                            Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String balance, String label, Color color) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Label Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getWalletIcon(label),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Balance
          Text(
            balance,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWalletIcon(String label) {
    switch (label.toLowerCase()) {
      case 'main wallet':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'groceries':
        return CupertinoIcons.cart_fill;
      case 'kid\'s wallet':
        return CupertinoIcons.person_2_fill;
      default:
        return CupertinoIcons.money_dollar;
    }
  }

  Widget _buildAddCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateWithFade(context),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 48,
                color: AppTheme.darkGreen.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Add New Wallet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.darkGreen.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    String name,
    String date,
    String amount,
    String type,
    Color avatarColor,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: avatarColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name[0],
              style: GoogleFonts.inter(
                color: avatarColor,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkGreen,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.darkGreen.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: amount.startsWith('+') ? Colors.green : AppTheme.darkGreen,
              ),
            ),
            Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.darkGreen.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateWithFade(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const WalletManagementScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
} 