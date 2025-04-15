import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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
                    // Header Section with Spending Info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 16.0, 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Spending',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.darkGreen.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '\$7,221.18',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: AppTheme.darkGreen.withOpacity(0.05),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Jul 2024',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppTheme.darkGreen.withOpacity(0.7),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppTheme.darkGreen.withOpacity(0.7),
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '↑ 4.9%',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'From last week',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.darkGreen.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Weekly Activity Bar Chart
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildDayBar('S', 0.3),
                          _buildDayBar('M', 0.5),
                          _buildDayBar('T', 0.7),
                          _buildDayBar('W', 1.0, isSelected: true),
                          _buildDayBar('T', 0.4),
                          _buildDayBar('F', 0.6),
                          _buildDayBar('S', 0.2),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Expense Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Expense',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.darkGreen.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                '-\$2,082.12',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 160,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 500,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: AppTheme.darkGreen.withOpacity(0.05),
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: 1,
                                      getTitlesWidget: (value, meta) {
                                        const months = [
                                          'Feb',
                                          'Mar',
                                          'Apr',
                                          'May',
                                          'Jun',
                                          'Jul'
                                        ];
                                        final index = value.toInt();
                                        if (index < 0 || index >= months.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            months[index],
                                            style: GoogleFonts.inter(
                                              color: AppTheme.darkGreen.withOpacity(0.5),
                                              fontSize: 11,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: const [
                                      FlSpot(0, 1200),
                                      FlSpot(1, 1600),
                                      FlSpot(2, 1900),
                                      FlSpot(3, 1700),
                                      FlSpot(4, 2100),
                                      FlSpot(5, 1975),
                                    ],
                                    isCurved: true,
                                    color: AppTheme.darkGreen,
                                    barWidth: 1.5,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 3,
                                          color: Colors.white,
                                          strokeWidth: 1.5,
                                          strokeColor: AppTheme.darkGreen,
                                        );
                                      },
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.darkGreen.withOpacity(0.15),
                                          AppTheme.darkGreen.withOpacity(0.0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                                minX: 0,
                                maxX: 5,
                                minY: 0,
                                maxY: 2500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Category Breakdown
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          _buildCategoryItem(
                            'Healthcare',
                            450.00,
                            Icons.local_hospital_outlined,
                            Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildCategoryItem(
                            'Food',
                            250.00,
                            Icons.restaurant_outlined,
                            Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildCategoryItem(
                            'Utilities',
                            275.00,
                            Icons.power_outlined,
                            Colors.purple,
                          ),
                          const SizedBox(height: 12),
                          _buildCategoryItem(
                            'Supplies',
                            150.00,
                            Icons.shopping_bag_outlined,
                            Colors.green,
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
                    _buildNavItem(Icons.home_rounded, false, context),
                    _buildNavItem(Icons.analytics_outlined, true, context),
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
        if (icon == Icons.home_rounded) {
          Navigator.pop(context);
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

  Widget _buildDayBar(String day, double height, {bool isSelected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: 20 * height,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.darkGreen
                : AppTheme.paleGreen.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day,
          style: GoogleFonts.inter(
            color: AppTheme.darkGreen.withOpacity(0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.darkGreen,
            ),
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGreen,
          ),
        ),
      ],
    );
  }
} 