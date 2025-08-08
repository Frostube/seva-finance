import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'expenses_screen.dart';
import 'profile_screen.dart';
import 'insights_screen.dart';
import '../services/onboarding_service.dart';
import '../services/analytics_service.dart';
import '../services/insights_service.dart';
import '../services/insight_notification_service.dart';
import '../widgets/onboarding_tour_overlay.dart';
import '../widgets/add_options_bottom_sheet.dart'; // Added import for AddOptionsBottomSheet

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // GlobalKeys for onboarding tour
  // Global keys for tour targeting - removed unused keys

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExpensesScreen(),
    const InsightsScreen(),
    const ProfileScreen(),
  ];

  // Removed unused _navLabels; BottomNavigationBar provides labels

  @override
  void initState() {
    super.initState();

    // Initialize AI services after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final analyticsService =
              Provider.of<AnalyticsService>(context, listen: false);
          final insightsService =
              Provider.of<InsightsService>(context, listen: false);
          final notificationService =
              Provider.of<InsightNotificationService>(context, listen: false);

          // Initialize services
          analyticsService.refreshAnalytics(force: true);
          insightsService.refreshInsights();
          notificationService.initializeListeners();

          // Check for critical alerts on app start
          notificationService.checkAndSendCriticalAlerts();
        } catch (e) {
          debugPrint('Error initializing AI services: $e');
        }
      }
    });
  }

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingService>(
      builder: (context, onboardingService, child) {
        return OnboardingTourOverlay(
          tourSteps: _buildTourSteps(context),
          onTourComplete: () {
            // Optional: Show success message or navigate somewhere
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome to Seva Finance! 🎉'),
                backgroundColor: Color(0xFF1B4332),
              ),
            );
          },
          onTourSkip: () {
            // Optional: Track skip analytics
            print('User skipped onboarding tour');
          },
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onNavigate,
                  type: Theme.of(context).bottomNavigationBarTheme.type ?? BottomNavigationBarType.fixed,
                  backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
                  selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
                  unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                  showUnselectedLabels: true,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                      tooltip: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      label: 'Budget',
                      tooltip: 'Budget',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.lightbulb_outline),
                      label: 'Insights',
                      tooltip: 'Insights',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                      tooltip: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              backgroundColor: const Color(0xFF1B4332),
              shape: const CircleBorder(),
              tooltip: 'Add',
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
          ),
        );
      },
    );
  }

  

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const AddOptionsBottomSheet();
      },
    );
  }

  List<TourStep> _buildTourSteps(BuildContext context) {
    return [
      TourStep(
        stepName: 'dashboard_overview',
        title: 'Your Financial Dashboard',
        description:
            'This is your financial overview where you can see your wallet balance, spending trends, and quick stats at a glance.',
        targetRect: _getDashboardOverviewRect(context),
        onStepAction: null, // Stay on dashboard
      ),
      TourStep(
        stepName: 'add_goal',
        title: 'Set Your Savings Goals',
        description:
            'Create savings goals to track your progress toward important financial targets. Tap "Goal" to set up your first savings goal.',
        targetRect: _getGoalButtonRect(context),
        onStepAction: null, // Stay on dashboard to show the goal button
      ),
      TourStep(
        stepName: 'add_alert',
        title: 'Set Spending Alerts',
        description:
            'Set up spending alerts to get notified when you\'re approaching your budget limits. Tap "Alert" to create your first spending alert.',
        targetRect: _getAlertButtonRect(context),
        onStepAction: null, // Stay on dashboard to show the alert button
      ),
      TourStep(
        stepName: 'expenses_navigation',
        title: 'Navigate to Expenses',
        description:
            'Tap on the "Budget" tab to access your expenses screen where you can add expenses and scan receipts.',
        targetRect: _getExpensesTabRect(context),
        onStepAction: () {
          // Navigate to expenses screen when this step is shown
          _onNavigate(1);
        },
      ),
      TourStep(
        stepName: 'quick_add',
        title: 'Quick Add',
        description:
            'Use the + button to quickly add expenses, scan receipts, and more.',
        targetRect: _getAddFabRect(context),
        onStepAction: null, // Stay on current screen
      ),
    ];
  }

  Rect _getDashboardOverviewRect(BuildContext context) {
    // Since we're on the dashboard screen, we'll target the top section
    final screenSize = MediaQuery.of(context).size;
    return Rect.fromLTWH(
      20,
      100, // Below the status bar and app bar
      screenSize.width - 40,
      200, // Height covering the greeting and wallet section
    );
  }

  Rect _getGoalButtonRect(BuildContext context) {
    // Target the "Goal" button on the dashboard
    final screenSize = MediaQuery.of(context).size;
    return Rect.fromLTWH(
      24, // Left padding
      screenSize.height * 0.55, // Approximate position of quick actions
      (screenSize.width - 80) / 2, // Half width minus padding and spacing
      56, // Button height
    );
  }

  Rect _getAlertButtonRect(BuildContext context) {
    // Target the "Alert" button on the dashboard
    final screenSize = MediaQuery.of(context).size;
    return Rect.fromLTWH(
      24 +
          (screenSize.width - 80) / 2 +
          16, // Left padding + first button width + spacing
      screenSize.height * 0.55, // Approximate position of quick actions
      (screenSize.width - 80) / 2, // Half width minus padding and spacing
      56, // Button height
    );
  }

  Rect _getExpensesTabRect(BuildContext context) {
    // Target the expenses tab (middle tab)
    final screenSize = MediaQuery.of(context).size;
    return Rect.fromLTWH(
      screenSize.width / 3, // Middle third of the screen
      screenSize.height - 85, // Bottom navigation bar height
      screenSize.width / 3, // Width of one tab
      85, // Height of bottom nav bar
    );
  }

  Rect _getAddFabRect(BuildContext context) {
    // Target the center-docked global + FAB
    final screenSize = MediaQuery.of(context).size;
    const double fabDiameter = 56;
    final double left = (screenSize.width - fabDiameter) / 2;
    final double top = screenSize.height - 85 - fabDiameter; // above bottom nav
    return Rect.fromLTWH(left, top, fabDiameter, fabDiameter);
  }

  // Removed unused floating action button methods since they're now in expenses screen
}
