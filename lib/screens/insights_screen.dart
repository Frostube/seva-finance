import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/insights_service.dart';
import '../services/analytics_service.dart';
import '../services/notification_service.dart';
import '../models/insight.dart';
import '../widgets/insight_card.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late InsightsService _insightsService;
  late AnalyticsService _analyticsService;
  late TabController _tabController;

  bool _isLoading = false;
  bool _isModalOpen = false;
  InsightType? _selectedFilter;

  final List<InsightType> _filterOptions = [
    InsightType.budgetAlert,
    InsightType.overspend,
    InsightType.forecastBalance,
    InsightType.categoryTrend,
    InsightType.savingOpportunity,
    InsightType.unusualSpending,
    InsightType.monthlyComparison,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeServices() async {
    _insightsService = Provider.of<InsightsService>(context, listen: false);
    _analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    // Auto-refresh insights if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshInsights();
    });
  }

  Future<void> _refreshInsights() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _insightsService.refreshInsights();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing insights: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cleanupDuplicates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _insightsService.forceDuplicateCleanup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Duplicate insights removed successfully'),
            backgroundColor: Color(0xFF1B4332),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing duplicates: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearAllInsights() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Insights'),
        content: const Text(
            'Are you sure you want to delete all insights? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _insightsService.clearAllInsights();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All insights cleared successfully'),
              backgroundColor: Color(0xFF1B4332),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing insights: $e'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  List<Insight> _getFilteredInsights(List<Insight> insights) {
    if (_selectedFilter == null) return insights;
    return insights
        .where((insight) => insight.type == _selectedFilter)
        .toList();
  }

  Future<void> _testNotifications() async {
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);

    // Create test notifications for insights
    await notificationService.addActionNotification(
      title: 'Balance Warning ⚠️',
      message:
          'Your balance may go negative by month-end. Consider reducing spending.',
      relatedId: 'test_insight_1',
    );

    await notificationService.addActionNotification(
      title: 'Spending Alert 💸',
      message:
          'Daily spending: \$45 ↑ vs \$32 baseline (+41%). Review recent transactions.',
      relatedId: 'test_insight_2',
    );

    await notificationService.addActionNotification(
      title: 'Financial Insight 💡',
      message:
          'Restaurants: \$180 ↑ vs \$120 last period (+50%). Set a category budget.',
      relatedId: 'test_insight_3',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Test notifications sent! Check your notifications screen.'),
          backgroundColor: Color(0xFF1B4332),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Insights',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1B4332)),
                    ),
                  )
                : const Icon(CupertinoIcons.refresh, color: Color(0xFF1B4332)),
            onPressed: _isLoading ? null : _refreshInsights,
          ),
          PopupMenuButton<String>(
            icon: const Icon(CupertinoIcons.ellipsis_vertical,
                color: Color(0xFF1B4332)),
            onSelected: (String action) async {
              if (action == 'cleanup') {
                await _cleanupDuplicates();
              } else if (action == 'clear_all') {
                await _clearAllInsights();
              } else if (action == 'test_notifications') {
                await _testNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'cleanup',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.delete_simple, size: 16),
                    SizedBox(width: 8),
                    Text('Remove Duplicates'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.clear, size: 16),
                    SizedBox(width: 8),
                    Text('Clear All Insights'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'test_notifications',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.bell, size: 16),
                    SizedBox(width: 8),
                    Text('Test Notifications'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<InsightType?>(
            icon: const Icon(CupertinoIcons.line_horizontal_3_decrease,
                color: Color(0xFF1B4332)),
            onSelected: (InsightType? filter) {
              setState(() {
                _selectedFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem<InsightType?>(
                value: null,
                child: Text('All Insights'),
              ),
              ..._filterOptions.map((type) => PopupMenuItem<InsightType>(
                    value: type,
                    child: Text(_getFilterDisplayName(type)),
                  )),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1B4332),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF1B4332),
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
          ],
        ),
      ),
      body: Consumer<InsightsService>(
        builder: (context, insightsService, child) {
          if (insightsService.isLoading && insightsService.insights.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B4332)),
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInsightsList(
                _getFilteredInsights(insightsService.insights),
                'No insights available yet',
              ),
              _buildInsightsList(
                _getFilteredInsights(insightsService.unreadInsights),
                'No unread insights',
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isModalOpen
          ? null
          : Consumer<AnalyticsService>(
              builder: (context, analyticsService, child) {
                final forecastedBalance =
                    analyticsService.getForecastedBalance();
                if (forecastedBalance == 0) return const SizedBox();

                return FloatingActionButton.extended(
                  heroTag: "insights_forecast_fab",
                  onPressed: () => _showForecastDialog(forecastedBalance),
                  backgroundColor: const Color(0xFF1B4332),
                  icon: const Icon(CupertinoIcons.graph_circle,
                      color: Colors.white),
                  label: Text(
                    'Balance Forecast',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInsightsList(List<Insight> insights, String emptyMessage) {
    if (insights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.lightbulb,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Insights will appear as you use the app',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshInsights,
      color: const Color(0xFF1B4332),
      child: CustomScrollView(
        slivers: [
          if (_selectedFilter != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Filtered by: ${_getFilterDisplayName(_selectedFilter!)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1B4332),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _selectedFilter = null),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          size: 16,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final insight = insights[index];
                  return InsightCard(
                    insight: insight,
                    onTap: () => _markAsRead(insight),
                    onDismiss: () => _dismissInsight(insight),
                  );
                },
                childCount: insights.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // FAB spacing
          ),
        ],
      ),
    );
  }

  void _markAsRead(Insight insight) async {
    if (!insight.isRead) {
      await _insightsService.markInsightAsRead(insight.id);
    }
  }

  void _dismissInsight(Insight insight) async {
    await _insightsService.deleteInsight(insight.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insight dismissed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Note: In a full implementation, you'd need to implement undo functionality
            },
          ),
        ),
      );
    }
  }

  void _showForecastDialog(double forecastedBalance) {
    final analytics = _analyticsService.currentAnalytics;
    final dailyAvg = analytics?.daysPassed != null && analytics!.daysPassed > 0
        ? analytics.mtdTotal / analytics.daysPassed
        : 0;
    final daysRemaining =
        DateTime.now().day <= 30 ? 30 - DateTime.now().day : 0;

    final isNegative = forecastedBalance < 0;
    final isLow = forecastedBalance > 0 && forecastedBalance < 500;

    setState(() {
      _isModalOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Disable background taps
      barrierColor: Colors.black.withOpacity(0.75), // Darker overlay
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
            minWidth: 280,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
                24, 32, 24, 40), // Increased top/bottom padding
            decoration: BoxDecoration(
              color: isNegative
                  ? Colors.red[50]
                  : isLow
                      ? Colors.orange[50]
                      : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment
                  .center, // Center align for better hierarchy
              children: [
                // Close button with proper touch target
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () {
                          setState(() {
                            _isModalOpen = false;
                          });
                          Navigator.pop(context);
                        },
                        child: const Icon(
                          CupertinoIcons.xmark,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  'Balance Forecast',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isNegative
                        ? Colors.red[800]
                        : isLow
                            ? Colors.orange[800]
                            : const Color(0xFF1B4332),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                Text(
                  'Projected balance by ${_getMonthEndDate()}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Number container with better visual hierarchy (80% width)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                      maxWidth: 320), // 80% of 400px max width
                  padding: const EdgeInsets.symmetric(
                      vertical: 24, horizontal: 20), // Added vertical padding
                  decoration: BoxDecoration(
                    color: isNegative
                        ? Colors.red[100]
                        : isLow
                            ? Colors.orange[100]
                            : const Color(0xFF1B4332).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isNegative
                          ? Colors.red[300]!
                          : isLow
                              ? Colors.orange[300]!
                              : const Color(0xFF1B4332).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Large balance number
                      Text(
                        '\$${forecastedBalance.abs().toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: isNegative
                              ? Colors.red[700]
                              : isLow
                                  ? Colors.orange[700]
                                  : const Color(0xFF1B4332),
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isNegative) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'NEGATIVE BALANCE',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Calculation explanation with proper padding
                      Container(
                        padding: const EdgeInsets.all(
                            16), // Added padding as requested
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Assumes \$${dailyAvg.toStringAsFixed(2)}/day spending',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'over the next $daysRemaining days',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    isNegative
                        ? 'Warning: You may go into the negative. Consider reducing spending or increasing income.'
                        : isLow
                            ? 'Your balance is running low. Monitor your spending closely and consider adjusting your budget.'
                            : forecastedBalance < 1000
                                ? 'You\'re on track for a modest balance by month-end. Keep up the good work!'
                                : 'Great! You\'re projected to have a healthy balance. Consider setting aside some savings.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Action buttons with better spacing
                Column(
                  children: [
                    // Primary action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isModalOpen = false;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isNegative
                              ? Colors.red[600]
                              : isLow
                                  ? Colors.orange[600]
                                  : const Color(0xFF1B4332),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16), // More rounded
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 18), // Increased padding
                          minimumSize: const Size(0, 52), // Larger touch target
                        ),
                        child: Text(
                          'Got it',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // Secondary action for concerning forecasts
                    if (isNegative || isLow) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isModalOpen = false;
                            });
                            Navigator.pop(context);
                            // Navigate to spending alerts or budget screen
                            _navigateToSecondaryAction(isNegative);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: isNegative
                                ? Colors.red[600]
                                : Colors.orange[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isNegative
                                    ? Colors.red[300]!
                                    : Colors.orange[300]!,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(0, 48),
                          ),
                          child: Text(
                            isNegative ? 'Set Spending Alert' : 'Adjust Budget',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Reset modal state when dialog closes (including back button/outside tap)
      if (mounted) {
        setState(() {
          _isModalOpen = false;
        });
      }
    });
  }

  String _getMonthEndDate() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} $lastDay';
  }

  void _navigateToSecondaryAction(bool isNegative) {
    if (isNegative) {
      // Navigate to spending alerts for negative forecasts
      Navigator.pushNamed(context, '/spending-alerts').catchError((_) {
        // Fallback if route doesn't exist - navigate to expenses screen
        Navigator.pop(context);
        Navigator.pushNamed(context, '/expenses');
      });
    } else {
      // Navigate to budget screen for low forecasts
      Navigator.pushNamed(context, '/budget').catchError((_) {
        // Fallback if route doesn't exist - navigate to expenses screen
        Navigator.pop(context);
        Navigator.pushNamed(context, '/expenses');
      });
    }
  }

  String _getFilterDisplayName(InsightType type) {
    switch (type) {
      case InsightType.overspend:
        return 'Overspending';
      case InsightType.forecastBalance:
        return 'Forecasts';
      case InsightType.categoryTrend:
        return 'Category Trends';
      case InsightType.budgetAlert:
        return 'Budget Alerts';
      case InsightType.savingOpportunity:
        return 'Savings';
      case InsightType.unusualSpending:
        return 'Unusual Spending';
      case InsightType.monthlyComparison:
        return 'Monthly Comparison';
      case InsightType.general:
        return 'General';
    }
  }
}
