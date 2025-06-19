import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
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
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:seva_finance/widgets/expense_tile.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/category_service.dart';
import '../services/savings_goal_service.dart';

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
  late StreamSubscription<BoxEvent> _walletBoxSubscription;
  bool _isScreenLoading = true;


  @override
  void initState() {
    super.initState();
    _initializeAsyncDependencies();

    // Listen for wallet changes
    _walletBoxSubscription =
        Hive.box<Wallet>('wallets').watch().listen((event) {
      _loadWallets();
    });
  }

  Future<void> _initializeAsyncDependencies() async {
    print('DashboardScreen: _initializeAsyncDependencies START');
    _walletService = Provider.of<WalletService>(context, listen: false);
    _categoryService = Provider.of<CategoryService>(context, listen: false);

    if (_walletService.initializationComplete != null) {
      print('DashboardScreen: Awaiting WalletService initialization...');
      await _walletService.initializationComplete;
      print('DashboardScreen: WalletService initialization COMPLETE');
    } else {
      print('DashboardScreen: WalletService.initializationComplete is null');
    }

    if (_categoryService.initializationComplete != null) {
      print('DashboardScreen: Awaiting CategoryService initialization...');
      await _categoryService.initializationComplete;
      print('DashboardScreen: CategoryService initialization COMPLETE');
    } else {
      print('DashboardScreen: CategoryService.initializationComplete is null');
    }

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

    _loadWallets();

    if (mounted) {
      setState(() {
        _isScreenLoading = false;
      });
    }
    print(
        'DashboardScreen: _initializeAsyncDependencies END, _isScreenLoading: \$_isScreenLoading');
  }

  @override
  void dispose() {
    _walletBoxSubscription.cancel();
    super.dispose();
  }

  void _loadWallets() {
    setState(() {
      _wallets = _walletService.getAllWallets();
    });
  }

  Widget _buildWalletCard(Wallet wallet) {
    return GestureDetector(
      onTap: () {
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
            if (wallet.isPrimary)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.star_fill,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Primary',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    Text(
                      wallet.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) => SetSavingsGoalSheet(
        walletId: wallet.id,
        savingsService: Provider.of<SavingsGoalService>(context, listen: false),
        onGoalAdded: () {
          // First close the bottom sheet
          Navigator.pop(bottomSheetContext);
          // Then update the state
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
        },
      ),
    );
  }

  void _showAddAlertSheet(Wallet wallet) {
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
          // Then update the state
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
        },
      ),
    );
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
    if (fullName == null || fullName.isEmpty) return 'User';
    return fullName.split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    print(
        'DashboardScreen: build called, _isScreenLoading: \$_isScreenLoading');
    if (_isScreenLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body:
            Center(child: CircularProgressIndicator(color: AppTheme.darkGreen)),
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
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Consumer<AuthService>(
                                builder: (context, authService, child) {
                                  return FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(authService.user?.uid)
                                        .get(),
                                    builder: (context, snapshot) {
                                      String firstName = 'User';
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        final userData = snapshot.data!.data()
                                            as Map<String, dynamic>?;
                                        if (userData != null &&
                                            userData['name'] != null) {
                                          firstName =
                                              _getFirstName(userData['name']);
                                        }
                                      }
                                      return Text(
                                        'Hi, $firstName',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.darkGreen,
                                        ),
                                      );
                                    },
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
                      height: 220, // Increased from 200 to accommodate buttons
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
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

                    // Recent Expenses Preview
                    _buildRecentExpensesPreview(),

                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpensesPreview() {
    return FutureBuilder<Map<String, List<Expense>>>(
      future: _expenseService.getExpensesByTimeline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No recent expenses'),
          );
        }

        final groupedExpenses = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (var entry in groupedExpenses.entries)
              if (entry.value.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                ...entry.value
                    .take(3)
                    .map((expense) => ExpenseTile(expense: expense)),
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
