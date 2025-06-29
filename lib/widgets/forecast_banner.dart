import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/analytics_service.dart';
import '../services/insights_service.dart';
import '../screens/insights_screen.dart';

class ForecastBanner extends StatelessWidget {
  const ForecastBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AnalyticsService, InsightsService>(
      builder: (context, analyticsService, insightsService, child) {
        final analytics = analyticsService.currentAnalytics;
        final forecastedBalance = analyticsService.getForecastedBalance();
        final unreadInsights = insightsService.unreadInsights;

        if (analytics == null && unreadInsights.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B4332),
                const Color(0xFF1B4332).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B4332).withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Insights',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (unreadInsights.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${unreadInsights.length} new',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Forecast Information
              if (analytics != null && forecastedBalance != 0) ...[
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.graph_circle,
                      color: Colors.white.withOpacity(0.9),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Month-end forecast:',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${forecastedBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getForecastMessage(forecastedBalance),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],

              // Recent Insights Preview
              if (unreadInsights.isNotEmpty) ...[
                if (analytics != null && forecastedBalance != 0)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                Text(
                  'Latest Insight:',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unreadInsights.first.text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 16),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InsightsScreen(),
                      ),
                    );
                  },
                  icon: Icon(
                    unreadInsights.isNotEmpty
                        ? CupertinoIcons.bell
                        : CupertinoIcons.chart_bar_alt_fill,
                    size: 18,
                    color: const Color(0xFF1B4332),
                  ),
                  label: Text(
                    unreadInsights.isNotEmpty
                        ? 'View ${unreadInsights.length} New Insights'
                        : 'View All Insights',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1B4332),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1B4332),
                    elevation: 2, // SevaFinance subtle elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          24), // SevaFinance rounded buttons
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14), // SevaFinance button height
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getForecastMessage(double forecastedBalance) {
    if (forecastedBalance < 0) {
      return 'Warning: You may go into the negative. Consider reducing spending.';
    } else if (forecastedBalance < 100) {
      return 'Your balance is running low. Monitor your spending closely.';
    } else if (forecastedBalance < 500) {
      return 'You\'re on track for a modest balance by month-end.';
    } else {
      return 'Great! You\'re projected to have a healthy balance.';
    }
  }
}
