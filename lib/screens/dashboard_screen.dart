import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'analytics_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                                onPressed: () {},
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
                            'Cards',
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
                            onPressed: () {},
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
                            '•••• 7381',
                            AppTheme.darkGreen,
                          ),
                          const SizedBox(width: 16),
                          _buildCard(
                            '\$3,421.63',
                            '•••• 7391',
                            Color(0xFF1E1E1E),
                          ),
                          const SizedBox(width: 16),
                          _buildAddCard(),
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
                              icon: const Icon(Icons.send),
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
                              icon: const Icon(Icons.download),
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
                              icon: Icon(
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
                                'Recent Activity',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {},
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
            // Bottom Navigation Bar
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_rounded, true, context),
                    _buildNavItem(Icons.analytics_outlined, false, context),
                    _buildScanButton(),
                    _buildNavItem(Icons.credit_card_outlined, false, context),
                    _buildNavItem(Icons.person_outline, false, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected, BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppTheme.darkGreen : Colors.grey,
        size: 28,
      ),
      onPressed: () {
        if (icon == Icons.analytics_outlined) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
          );
        }
      },
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGreen.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(
            Icons.document_scanner_outlined,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildCard(String balance, String cardNumber, Color color) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                balance,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Icon(
                Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.8),
              ),
            ],
          ),
          Text(
            cardNumber,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCard() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkGreen.withOpacity(0.1),
          width: 2,
        ),
      ),
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
            'Add New Card',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.darkGreen.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
} 