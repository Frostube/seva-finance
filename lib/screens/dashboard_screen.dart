import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/layout.dart';
import '../theme/app_theme.dart';
// import '../theme/colors.dart'; // Deprecated in favor of AppTheme / ColorScheme
import 'linked_cards_screen.dart';
import 'notifications_screen.dart';
import '../services/wallet_service.dart';
import '../services/spending_alert_service.dart';
import '../models/wallet.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import 'edit_wallet_screen.dart';
import 'set_savings_goal_sheet.dart';
import 'set_spending_alert_sheet.dart';
import 'goals_and_alerts_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:hive/hive.dart'; // duplicate
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:seva_finance/widgets/expense_tile.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/savings_goal_service.dart';
import '../widgets/forecast_banner.dart';
// import '../widgets/help_icon.dart';
import '../widgets/chat_modal.dart';
// import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/trial_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../widgets/suggestion_bar.dart';
import 'package:hive/hive.dart';
import 'package:dots_indicator/dots_indicator.dart'; // Import for dots indicator
import '../services/coach_service.dart'; // Import CoachService
import '../widgets/coach_card.dart'; // Import CoachCard
// import '../services/feature_gate_service.dart'; // Import FeatureGateService
// import '../services/subscription_service.dart'; // Import SubscriptionService
import 'expenses_screen.dart'; // For expenses screen
import 'add_budget_screen.dart'; // For budgets screen
import 'insights_screen.dart'; // For insights screen
import 'help_faqs_screen.dart'; // For help screen
import '../services/feature_flag_service.dart'; // Corrected import for FeatureFlagService

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late WalletService _walletService;
  late ExpenseService _expenseService;
  late CategoryService _categoryService;
  List<Wallet> _wallets = [];
  String? _cachedFirstName; // Fallback from Firestore
  late StreamSubscription<BoxEvent> _walletBoxSubscription;
  bool _isScreenLoading = true;
  bool _showChatButton = false; // New state variable
  Timer? _chatButtonTimer; // Timer for delayed appearance
  List<CoachTip> _coachTips = []; // List to hold coach tips
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _hasInitializationError = false; // New state for initialization errors
  Timer? _tipsAutoPlayTimer; // Auto-advance timer for coach tips

  @override
  void initState() {
    super.initState();
    _initializeAsyncDependencies();
    _startChatButtonTimer(); // Start the timer when the screen initializes
    _loadCoachTips(); // Load coach tips

    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });

    // Listen for wallet changes
    _walletBoxSubscription =
        Hive.box<Wallet>('wallets').watch().listen((event) {
      _loadWallets();
    });
  }

  Future<void> _initializeAsyncDependencies() async {
    print('DashboardScreen: _initializeAsyncDependencies START');

    if (!mounted) return;

    try {
      _walletService = Provider.of<WalletService>(context, listen: false);
      _categoryService = Provider.of<CategoryService>(context, listen: false);

      // Wait for WalletService initialization
      if (_walletService.initializationComplete != null) {
        print('DashboardScreen: Awaiting WalletService initialization...');
        await _walletService.initializationComplete;
        print('DashboardScreen: WalletService initialization COMPLETE');
      } else {
        print('DashboardScreen: WalletService.initializationComplete is null');
      }

      if (!mounted) return;

      // Wait for CategoryService initialization
      if (_categoryService.initializationComplete != null) {
        print('DashboardScreen: Awaiting CategoryService initialization...');
        await _categoryService.initializationComplete;
        print('DashboardScreen: CategoryService initialization COMPLETE');
      } else {
        print(
            'DashboardScreen: CategoryService.initializationComplete is null');
      }

      if (!mounted) return;

      // Initialize ExpenseService
      _expenseService = ExpenseService(
        Hive.box<Expense>('expenses'),
        _walletService,
        Provider.of<NotificationService>(context, listen: false),
        Provider.of<FirebaseFirestore>(context, listen: false),
        _categoryService,
      );

      if (_expenseService.initializationComplete != null) {
        print('DashboardScreen: Awaiting ExpenseService initialization...');
        await _expenseService.initializationComplete;
        print('DashboardScreen: ExpenseService initialization COMPLETE');
      } else {
        print('DashboardScreen: ExpenseService.initializationComplete is null');
      }

      if (!mounted) return;

      // Fetch name from Firestore as a fallback so greeting uses actual profile name
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final fullName = (doc.data()?['name'] as String?)?.trim() ?? '';
          if (fullName.isNotEmpty && mounted) {
            setState(() {
              _cachedFirstName = _extractFirstName(fullName);
            });
          }
        }
      } catch (e) {
        print('DashboardScreen: Failed to fetch name fallback: $e');
      }

      // Generate coach tips after all services are initialized
      final coachService = Provider.of<CoachService>(context, listen: false);
      final featureFlagService =
          Provider.of<FeatureFlagService>(context, listen: false);

      if (featureFlagService.isAiFeaturesEnabled) {
        await coachService.loadCoachTips(); // Corrected method name
        await coachService
            .generateCoachTips(); // Call generateCoachTips as well
      }

      // Load wallets only if we're still mounted
      _loadWallets();

      if (mounted) {
        setState(() {
          _isScreenLoading = false;
          _coachTips = coachService.tips; // Load tips into local state
        });
        _startTipsAutoPlay();
      }

      print(
          'DashboardScreen: _initializeAsyncDependencies END, _isScreenLoading: $_isScreenLoading');
    } catch (e) {
      print('DashboardScreen: Error during initialization: $e');
      if (mounted) {
        setState(() {
          _isScreenLoading = false;
          _hasInitializationError = true; // Set error state
        });
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _walletBoxSubscription.cancel();
    _chatButtonTimer?.cancel(); // Cancel the timer when the widget is disposed
    _tipsAutoPlayTimer?.cancel();
    _pageController.dispose(); // Dispose the PageController
    super.dispose();
  }

  Future<void> _loadCoachTips() async {
    final coachService = Provider.of<CoachService>(context, listen: false);
    await coachService.loadCoachTips();
    setState(() {
      _coachTips = coachService.tips; // Update list of tips from service
    });
    _startTipsAutoPlay();
  }

  void _startChatButtonTimer() async {
    final chatBox = await Hive.openBox<bool>('chat_settings');
    final hasInteractedWithDashboard =
        chatBox.get('hasInteractedWithDashboard', defaultValue: false)!;

    if (hasInteractedWithDashboard) {
      setState(() {
        _showChatButton = true;
      });
    } else {
      _chatButtonTimer = Timer(const Duration(seconds: 30), () {
        if (mounted) {
          setState(() {
            _showChatButton = true;
            chatBox.put('hasInteractedWithDashboard', true); // Persist state
          });
        }
      });
    }
  }

  void _recordDashboardInteraction() async {
    final chatBox = await Hive.openBox<bool>('chat_settings');
    if (!chatBox.get('hasInteractedWithDashboard', defaultValue: false)!) {
      chatBox.put('hasInteractedWithDashboard', true);
      setState(() {
        _showChatButton = true;
      });
    }
  }

  void _startTipsAutoPlay() {
    _tipsAutoPlayTimer?.cancel();
    if (_coachTips.length <= 1) return;
    _tipsAutoPlayTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      final current = _pageController.hasClients
          ? (_pageController.page?.round() ?? 0)
          : 0;  // 5 seconds
      final next = (current + 1) % _coachTips.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _loadWallets() {
    if (!mounted) return;

    try {
      final wallets = _walletService.getAllWallets();
      // Ensure primary wallet appears first
      wallets.sort((a, b) {
        if (a.isPrimary == b.isPrimary) return 0;
        return a.isPrimary ? -1 : 1;
      });
      if (mounted) {
        setState(() {
          _wallets = wallets;
        });
      }
    } catch (e) {
      print('DashboardScreen: Error loading wallets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading wallets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildWalletCard(Wallet wallet) {
    return GestureDetector(
      onTap: () {
        _recordDashboardInteraction(); // Record interaction
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditWalletScreen(
              wallet: wallet,
              onWalletUpdated: _loadWallets,
            ),
          ),
        );
      },
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(wallet.colorValue),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(wallet.colorValue).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Removed overlay badge to avoid overlapping; show inline chip near name instead
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        wallet.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              wallet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (wallet.isPrimary) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(CupertinoIcons.star_fill,
                                      size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Primary',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  NumberFormat.currency(
                    symbol: '\$',
                    decimalDigits:
                        wallet.balance.truncateToDouble() == wallet.balance
                            ? 0
                            : 2,
                  ).format(wallet.balance),
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (wallet.budget != null && wallet.budget! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Budget: ${NumberFormat.currency(
                      symbol: '\$',
                      decimalDigits:
                          wallet.budget!.truncateToDouble() == wallet.budget
                              ? 0
                              : 2,
                    ).format(wallet.budget!)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalSheet(Wallet wallet) {
    if (!mounted) return;

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext bottomSheetContext) => SetSavingsGoalSheet(
          walletId: wallet.id,
          savingsService:
              Provider.of<SavingsGoalService>(context, listen: false),
          onGoalAdded: () {
            // First close the bottom sheet
            Navigator.pop(bottomSheetContext);
            // Then update the state if still mounted
            if (mounted) {
              setState(() {});
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Savings goal added successfully',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: const Color(0xFF1B4332),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      );
    } catch (e) {
      print('DashboardScreen: Error showing add goal sheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding savings goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddAlertSheet(Wallet wallet) {
    if (!mounted) return;

    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext bottomSheetContext) => SetSpendingAlertSheet(
          walletId: wallet.id,
          savingsService:
              Provider.of<SpendingAlertService>(context, listen: false),
          onAlertAdded: () {
            // First close the bottom sheet
            Navigator.pop(bottomSheetContext);
            // Then update the state if still mounted
            if (mounted) {
              setState(() {});
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Spending alert added successfully',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: const Color(0xFF1B4332),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      );
    } catch (e) {
      print('DashboardScreen: Error showing add alert sheet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding spending alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToGoalsAndAlerts(Wallet wallet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalsAndAlertsScreen(
          walletId: wallet.id,
          spendingAlertService:
              Provider.of<SpendingAlertService>(context, listen: false),
          savingsGoalService:
              Provider.of<SavingsGoalService>(context, listen: false),
        ),
      ),
    );
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

  String _getFirstName(String? fullName) {
    // Prefer provided name, then Firebase displayName, then first part of email
    String candidate = (fullName ?? '').trim();
    if (candidate.isEmpty) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      candidate = (firebaseUser?.displayName ?? '').trim();
      if (candidate.isEmpty) {
        final email = (firebaseUser?.email ?? '').trim();
        if (email.isNotEmpty) {
          candidate = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
        }
      }
    }

    if (candidate.isEmpty) return 'User';
    final first = candidate.split(' ').first;
    if (first.isEmpty) return 'User';
    return first[0].toUpperCase() + first.substring(1);
  }

  String _extractFirstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'User';
    final first = trimmed.split(' ').first;
    return first.isEmpty ? 'User' : first[0].toUpperCase() + first.substring(1);
  }

  void _showChatModal(BuildContext context) {
    if (!mounted) return;

    try {
      showDialog(
        context: context,
        builder: (context) => const ChatModal(),
      );
    } catch (e) {
      print('DashboardScreen: Error showing chat modal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DashboardScreen: build called, _isScreenLoading: $_isScreenLoading');
    if (_isScreenLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body:
            Center(child: CircularProgressIndicator(color: AppTheme.darkGreen)),
      );
    }

    if (_hasInitializationError) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load data.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isScreenLoading = true; // Show loading indicator again
                    _hasInitializationError = false; // Reset error state
                  });
                  _initializeAsyncDependencies(); // Retry initialization
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                      padding: LayoutUtils.pagePadding(context, top: 24, bottom: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<UserService>(
                                builder: (context, userService, child) {
                                  // Prefer stored full name; avoid falling back to email here
                                  final name = (userService.currentUser?.name ?? '').trim();
                                  final firstName = name.isNotEmpty
                                      ? _extractFirstName(name)
                                      : (_cachedFirstName ?? _getFirstName(''));
                                  return Text(
                                    'Hi, $firstName',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkGreen,
                                    ),
                                  );
                                },
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
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                              Consumer<NotificationService>(
                                builder: (context, notificationService, child) {
                                  return notificationService
                                          .hasUnreadNotifications
                                      ? Positioned(
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
                                        )
                                      : const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Trial banner for active trials
                    const TrialBanner(),

                    // Wallet Balance Text
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: LayoutUtils.responsiveHorizontalPadding(context)),
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
                      height: 220, // Increased from 200 to accommodate buttons
                      child: ListView(
                        padding: EdgeInsets.symmetric(
                          horizontal: LayoutUtils.responsiveHorizontalPadding(context) - 8,
                          vertical: 16.0,
                        ),
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._wallets.map((wallet) => Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _buildWalletCard(wallet),
                              )),
                          _buildAddCard(context),
                        ],
                      ),
                    ),

                    // Quick Actions
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: LayoutUtils.responsiveHorizontalPadding(context)),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _wallets.isNotEmpty
                                  ? () => _showAddGoalSheet(_wallets.first)
                                  : () => _showNoWalletDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                  CupertinoIcons.money_dollar_circle,
                                  size: 20),
                              label: const Text('Goal'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _wallets.isNotEmpty
                                  ? () => _showAddAlertSheet(_wallets.first)
                                  : () => _showNoWalletDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.paleGreen,
                                foregroundColor: AppTheme.darkGreen,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(CupertinoIcons.bell, size: 20),
                              label: const Text('Alert'),
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
                                CupertinoIcons.list_bullet,
                                color: AppTheme.darkGreen,
                              ),
                              onPressed: _wallets.isNotEmpty
                                  ? () =>
                                      _navigateToGoalsAndAlerts(_wallets.first)
                                  : () => _showNoWalletDialog(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // AI Insights Forecast Banner
                    const ForecastBanner(),

                    // Coach Cards Carousel
                    if (_coachTips.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            height: 150, // Increased to prevent overflow for longer tips
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _coachTips.length,
                              itemBuilder: (context, index) {
                                final tip = _coachTips[index];
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 350),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: CoachCard(
                                    key: ValueKey(tip.id),
                                    tip: tip,
                                    onDismiss: () {
                                      setState(() {
                                        _coachTips.removeAt(index);
                                      });
                                    },
                                    onLearnMore: tip.relatedScreen != null
                                        ? () => _navigateToCoachRelatedScreen(
                                            tip.relatedScreen!)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_coachTips.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: DotsIndicator(
                                dotsCount: _coachTips.length,
                                position:
                                    _currentPage.toDouble(), // Cast to double
                                decorator: DotsDecorator(
                                  size: const Size.square(9.0),
                                  activeSize: const Size(18.0, 9.0),
                                  activeShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.0)),
                                  activeColor: AppTheme.darkGreen,
                                  color: Colors.grey[300]!,
                                ),
                              ),
                            ),
                        ],
                      ),

                    // Suggestion Bar (hidden until real suggestions are available)
                    const SizedBox.shrink(),

                    // Recent Expenses Preview in a card for better grouping
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: LayoutUtils.responsiveHorizontalPadding(context) - 8,
                          vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Recent Expenses',
                                      style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.w600) ??
                                          const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ExpensesScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text('View All'),
                                    )
                                  ],
                                ),
                              ),
                              _buildRecentExpensesPreview(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 0), // Removed fixed space that caused overflow
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkGreen,
              AppTheme.primaryGreen,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkGreen.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedOpacity(
          opacity: _showChatButton ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: IgnorePointer(
            ignoring: !_showChatButton,
            child: FloatingActionButton(
              heroTag: "dashboard_chat_fab",
              onPressed: () {
                _recordDashboardInteraction(); // Record interaction
                _showChatModal(context);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                CupertinoIcons.chat_bubble_text_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCoachRelatedScreen(String screenName) {
    print('Navigating to coach related screen: $screenName');
    switch (screenName) {
      case 'budget':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddBudgetScreen(
                    currentBudget: 0.0,
                    onBudgetUpdated: () {}))); // Corrected onBudgetUpdated
        break;
      case 'expenses':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ExpensesScreen()));
        break;
      case 'savings':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GoalsAndAlertsScreen(
                      walletId: _wallets.isNotEmpty
                          ? _wallets.first.id
                          : '', // Provide walletId
                      spendingAlertService: Provider.of(context, listen: false),
                      savingsGoalService: Provider.of(context, listen: false),
                    )));
        break;
      case 'insights':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const InsightsScreen()));
        break;
      case 'goals':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GoalsAndAlertsScreen(
                      walletId: _wallets.isNotEmpty
                          ? _wallets.first.id
                          : '', // Provide walletId
                      spendingAlertService: Provider.of(context, listen: false),
                      savingsGoalService: Provider.of(context, listen: false),
                    )));
        break;
      case 'help':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HelpFAQsScreen()));
        break;
      default:
        // Optionally, navigate to a general dashboard or show an error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation for $screenName is not yet implemented.'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
    }
  }

  Widget _buildRecentExpensesPreview() {
    return FutureBuilder<Map<String, List<Expense>>>(
      future: _expenseService.getExpensesByTimeline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Center(
              child: Text('No recent expenses'),
            ),
          );
        }

        final groupedExpenses = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var entry in groupedExpenses.entries)
              if (entry.value.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 8.0),
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ) ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                ...entry.value
                    .take(3)
                    .map((expense) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: ExpenseTile(expense: expense),
                        )),
              ],
          ],
        );
      },
    );
  }

  void _navigateWithFade(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LinkedCardsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _showNoWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'No Wallet Found',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Please create a wallet first before setting up goals or alerts.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateWithFade(context); // Navigate to wallet creation
            },
            child: Text(
              'Create Wallet',
              style: GoogleFonts.inter(
                color: AppTheme.darkGreen,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
