import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // For iOS-style icons
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // For StreamSubscription
import 'add_expense_screen.dart';
import '../services/expense_service.dart';
import '../models/expense.dart';
import '../models/wallet.dart'; // For Wallet model
import 'transaction_detail_screen.dart';
import 'add_budget_screen.dart';
import 'remove_budget_screen.dart';
import 'recent_expenses_screen.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import '../services/wallet_service.dart';
import 'edit_wallet_screen.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/category_service.dart';
import '../services/category_budget_service.dart';
import '../widgets/template_picker_modal.dart';
import '../widgets/category_budget_tracker.dart';
import '../widgets/loading_widget.dart';
import '../models/budget_template.dart';
import '../models/template_item.dart';
import 'budget_creation_screen.dart';
import 'ocr_screen.dart'; // Added for OCR screen navigation
import 'import_screen.dart';
import 'export_screen.dart';
import '../services/coach_service.dart';
import '../widgets/coach_card.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late ExpenseService _expenseService;
  late WalletService _walletService;
  late CategoryService _categoryService;
  late CoachService _coachService;
  double? _monthlyBudget;
  late StreamSubscription<BoxEvent> _walletBoxSubscription;

  // Add selectedMonth state
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  int _refreshCounter = 0; // Add this counter

  // State variables for "My Spending" card
  double _currentWeekTotal = 0.0;
  double _previousWeekTotal = 0.0;
  List<double> _dailyTotalsForChart = List.filled(7, 0.0); // Monday to Sunday
  bool _isMySpendingLoading = true;
  double _spendingTrend = 0.0;

  // State variables for 6-Month Expense Overview Line Chart (NEW)
  List<FlSpot> _sixMonthChartSpots = [];
  List<String> _sixMonthChartLabels = [];
  bool _isSixMonthChartLoading = true;
  double _maxSixMonthSpending = 0.0; // For Y-axis scaling
  bool _isScreenInitialized = false; // Added for screen-level initialization

  final Map<String, IconData> _categoryIcons = {
    'Rent': CupertinoIcons.house_fill,
    'Groceries': CupertinoIcons.cart_fill,
    'Transport': CupertinoIcons.car_fill,
    'Shopping': CupertinoIcons.bag_fill,
    'Entertainment': CupertinoIcons.film,
    'Bills': CupertinoIcons.doc_text,
    'Health': CupertinoIcons.heart,
    'Other': CupertinoIcons.square_grid_2x2,
  };

  @override
  void initState() {
    super.initState();
    print('ExpensesScreen: initState called');
    _initializeAsyncDependencies(); // Call the new async init method

    // Listen for wallet changes
    _walletBoxSubscription =
        Hive.box<Wallet>('wallets').watch().listen((event) {
      _loadBudget();
    });
  }

  // New async method for initialization
  Future<void> _initializeAsyncDependencies() async {
    print('ExpensesScreen: _initializeAsyncDependencies START');

    // Fetch WalletService first and await its initialization
    _walletService = Provider.of<WalletService>(context, listen: false);
    if (_walletService.initializationComplete != null) {
      print('ExpensesScreen: Awaiting WalletService initialization...');
      await _walletService.initializationComplete;
      print('ExpensesScreen: WalletService initialization COMPLETE');
    } else {
      print(
          'ExpensesScreen: WalletService.initializationComplete is null, proceeding cautiously.');
    }

    _categoryService = Provider.of<CategoryService>(context,
        listen: false); // Initialize CategoryService
    if (_categoryService.initializationComplete != null) {
      print('ExpensesScreen: Awaiting CategoryService initialization...');
      await _categoryService.initializationComplete;
      print('ExpensesScreen: CategoryService initialization COMPLETE');
    }

    _coachService = Provider.of<CoachService>(context, listen: false);

    _expenseService = ExpenseService(
      Hive.box<Expense>('expenses'),
      Provider.of<WalletService>(context, listen: false),
      Provider.of<NotificationService>(context, listen: false),
      Provider.of<FirebaseFirestore>(context, listen: false),
      _categoryService, // Pass the initialized CategoryService instance
    );

    if (_expenseService.initializationComplete != null) {
      print('ExpensesScreen: Awaiting ExpenseService initialization...');
      await _expenseService.initializationComplete;
      print('ExpensesScreen: ExpenseService initialization COMPLETE');
    } else {
      print(
          'ExpensesScreen: ExpenseService initializationComplete future is null, proceeding without await.');
    }

    // Now that ExpenseService is initialized, load screen-specific data
    // Use mounted check before calling setState in async methods if they might complete after dispose
    if (!mounted) return;
    await _loadBudget(); // Make sure _loadBudget is also async if it needs to be
    if (!mounted) return;
    await _loadMySpendingData(); // Load data for "My Spending" card
    if (!mounted) return;
    await _loadSixMonthChartData(); // Load 6-month overview chart data

    if (mounted) {
      setState(() {
        _isScreenInitialized = true;
      });
    }
    print(
        'ExpensesScreen: _initializeAsyncDependencies END, _isScreenInitialized: \$_isScreenInitialized');
  }

  @override
  void dispose() {
    print('ExpensesScreen: dispose called');
    _walletBoxSubscription.cancel();
    super.dispose();
  }

  Widget _buildNoWalletView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.money_dollar_circle,
              size: 64,
              color: Color(0xFF1B4332),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Seva Finance',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'To get started, create a wallet to track your expenses and budget',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                final newWallet = Wallet(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'New Wallet',
                  balance: 0.0,
                  isPrimary: true, // First wallet is primary
                  createdAt: DateTime.now(),
                  colorValue: const Color(0xFF1E1E1E).value,
                );
                _walletService.addWallet(newWallet).then((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditWalletScreen(
                        wallet: newWallet,
                        onWalletUpdated: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.plus_circle_fill,
                      color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Create Your First Wallet',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBudget() async {
    print('ExpensesScreen: _loadBudget called for month: $_selectedMonth');
    final primaryWallet = _walletService.getPrimaryWallet();
    print('ExpensesScreen: primaryWallet: $primaryWallet');

    setState(() {
      _monthlyBudget = primaryWallet?.budget ?? 0.0;
    });
    print('ExpensesScreen: _monthlyBudget set to: $_monthlyBudget');
    await _updateCachedValues();
  }

  Future<void> _loadMySpendingData() async {
    if (!mounted) return;
    setState(() {
      _isMySpendingLoading = true;
    });
    print('ExpensesScreen: _loadMySpendingData START');

    try {
      final now = DateTime.now();
      print('ExpensesScreen: _loadMySpendingData - now: $now');

      // Current week (Monday to Sunday)
      final int currentWeekday = now.weekday; // 1 (Mon) to 7 (Sun)
      print(
          'ExpensesScreen: _loadMySpendingData - currentWeekday (1-Mon, 7-Sun): $currentWeekday');

      // Calculate Monday of the current week, at the very start of the day
      DateTime mondayOfCurrentWeek = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: currentWeekday - 1));

      final DateTime startOfCurrentWeek =
          mondayOfCurrentWeek; // Already at 00:00:00
      final DateTime endOfCurrentWeek = mondayOfCurrentWeek
          .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      print(
          'ExpensesScreen: _loadMySpendingData - startOfCurrentWeek (Mon): $startOfCurrentWeek, endOfCurrentWeek (Sun): $endOfCurrentWeek');

      // Previous week
      final DateTime startOfPreviousWeek =
          startOfCurrentWeek.subtract(const Duration(days: 7));
      final DateTime endOfPreviousWeek = startOfCurrentWeek
          .subtract(const Duration(seconds: 1)); // End of Sunday previous week
      print(
          'ExpensesScreen: _loadMySpendingData - startOfPreviousWeek (Mon): $startOfPreviousWeek, endOfPreviousWeek (Sun): $endOfPreviousWeek');

      _currentWeekTotal = await _expenseService.getTotalExpensesForDateRange(
          startOfCurrentWeek, endOfCurrentWeek);
      print(
          'ExpensesScreen: _loadMySpendingData - _currentWeekTotal from service: $_currentWeekTotal');
      _previousWeekTotal = await _expenseService.getTotalExpensesForDateRange(
          startOfPreviousWeek, endOfPreviousWeek);
      print(
          'ExpensesScreen: _loadMySpendingData - _previousWeekTotal from service: $_previousWeekTotal');
      _dailyTotalsForChart = await _expenseService.getDailyExpensesForWeek(now);
      print(
          'ExpensesScreen: _loadMySpendingData - _dailyTotalsForChart from service: $_dailyTotalsForChart');

      if (_previousWeekTotal > 0) {
        _spendingTrend =
            (_currentWeekTotal - _previousWeekTotal) / _previousWeekTotal;
      } else if (_currentWeekTotal > 0) {
        _spendingTrend =
            1.0; // Effectively +100% if previous was 0 and current is > 0
      } else {
        _spendingTrend = 0.0; // No change if both are 0
      }
    } catch (e) {
      print('Error loading my spending data: $e');
      // Set to default values in case of error
      _currentWeekTotal = 0.0;
      _previousWeekTotal = 0.0;
      _dailyTotalsForChart = List.filled(7, 0.0);
      _spendingTrend = 0.0;
    }

    setState(() {
      _isMySpendingLoading = false;
    });
    print('ExpensesScreen: _loadMySpendingData END');
  }

  Future<void> _loadSixMonthChartData() async {
    if (!mounted) return;
    setState(() {
      _isSixMonthChartLoading = true;
    });
    print('ExpensesScreen: _loadSixMonthChartData START');
    try {
      final chartData =
          await _expenseService.getMonthlyExpenseSummaryForLastSixMonths();
      setState(() {
        _sixMonthChartSpots = chartData['spots'] as List<FlSpot>;
        _sixMonthChartLabels = chartData['monthLabels'] as List<String>;
        // Add 20% padding to max spending for Y-axis, or default if no spending
        final rawMaxSpending = chartData['maxSpending'] as double;
        _maxSixMonthSpending = rawMaxSpending > 0 ? rawMaxSpending * 1.2 : 100;
      });
    } catch (e) {
      print('Error loading 6-month chart data: $e');
      setState(() {
        _sixMonthChartSpots = [];
        _sixMonthChartLabels = [];
        _maxSixMonthSpending = 100; // Default Y-axis max on error
      });
    }
    setState(() {
      _isSixMonthChartLoading = false;
    });
    print(
        'ExpensesScreen: _loadSixMonthChartData END - Spots: ${_sixMonthChartSpots.length}, Labels: ${_sixMonthChartLabels.length}');
  }

  Future<void> _updateCachedValues() async {
    print(
        'ExpensesScreen: Updating cached values for ${DateFormat('MMMM yyyy').format(_selectedMonth)}');
    setState(() {
      _refreshCounter++;
    });
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _refreshScreen() {
    setState(() {
      _refreshCounter++;
      print(
          'ExpensesScreen: _refreshScreen called, counter is now: $_refreshCounter');
    });
    _loadMySpendingData();
    _loadSixMonthChartData();
  }

  Future<void> _dismissTip(CoachTip tip) async {
    try {
      await _coachService.dismissTip(tip.id);
    } catch (e) {
      print('Error dismissing coach tip: $e');
    }
  }

  void _handleCoachAction(CoachTip tip) {
    // Handle different types of coach tip actions
    switch (tip.type) {
      case CoachTipType.budgetAlert:
        _showAddBudgetScreen();
        break;
      case CoachTipType.spendingPattern:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecentExpensesScreen(
              expenseService: _expenseService,
            ),
          ),
        );
        break;
      case CoachTipType.savingOpportunity:
        _showTemplatePickerModal();
        break;
      default:
        // For other types, show a generic message or do nothing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Learn more about: ${tip.title}'),
            backgroundColor: const Color(0xFF1B4332),
          ),
        );
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    ).format(amount);
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.plus,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  title: Text(
                    'Add Expense',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    print(
                        'ExpensesScreen: Add Expense Tapped in _showAddOptions');
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => AddExpenseScreen(
                          expenseService: _expenseService,
                          onExpenseAdded: _refreshScreen,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.chart_pie_fill,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  title: Text(
                    'Choose Template',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Quick budget setup',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showTemplatePickerModal();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  title: Text(
                    'Add Budget',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddBudgetScreen();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.minus,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  title: Text(
                    'Remove Budget',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRemoveBudgetScreen();
                  },
                ),
                const Divider(height: 32),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.cloud_upload,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  title: Text(
                    'Import Expenses',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Upload CSV/Excel files',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showImportScreen();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.cloud_download,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  title: Text(
                    'Export Expenses',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Download as CSV/Excel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showExportScreen();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddBudgetScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(
          currentBudget: _monthlyBudget ?? 0.0,
          onBudgetUpdated: _loadBudget,
        ),
      ),
    );
  }

  void _showRemoveBudgetScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RemoveBudgetScreen(
          currentBudget: _monthlyBudget ?? 0.0,
          onBudgetUpdated: _loadBudget,
        ),
      ),
    );
  }

  void _showImportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ImportScreen(),
      ),
    ).then((_) => _refreshScreen());
  }

  void _showExportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExportScreen(),
      ),
    );
  }

  void _showTemplatePickerModal() {
    final primaryWallet = _walletService.getPrimaryWallet();
    if (primaryWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please create a wallet first',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplatePickerModal(
        walletId: primaryWallet.id,
        onTemplateSelected: () {
          // Refresh budget and expenses data after template is applied
          _loadBudget();
          setState(() {
            _refreshCounter++;
          });
        },
      ),
    );
  }

  void _editCurrentBudget() async {
    print('ExpensesScreen: _editCurrentBudget called');

    final primaryWallet = _walletService.getPrimaryWallet();
    if (primaryWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please create a wallet first',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current month's category budgets
    final categoryBudgetService =
        Provider.of<CategoryBudgetService>(context, listen: false);
    final categoryBudgets = categoryBudgetService
        .getCategoryBudgetsForWalletAndMonth(primaryWallet.id, _selectedMonth);

    if (categoryBudgets.isEmpty) {
      // No budget exists, show template picker instead
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No budget found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}. Please choose a template first.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      _showTemplatePickerModal();
      return;
    }

    // Convert category budgets to template items for editing
    final templateItems = categoryBudgets.asMap().entries.map((entry) {
      final index = entry.key;
      final budget = entry.value;
      return TemplateItem(
        id: budget.id,
        templateId: budget.templateId ?? '',
        categoryId: budget.categoryId,
        defaultAmount: budget.budgetAmount,
        order: index,
      );
    }).toList();

    // Create a temporary template for editing
    final editTemplate = BudgetTemplate(
      id: 'edit_current_budget',
      name: 'Edit Budget - ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
      description:
          'Modify your budget for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
      isSystem: false,
      createdBy: null,
      createdAt: DateTime.now(),
      timeline: BudgetTimeline.monthly,
      endDate: null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetCreationScreen(
          walletId: primaryWallet.id,
          selectedTemplate: editTemplate,
          templateItems: templateItems,
          onBudgetCreated: () {
            // Refresh budget and expenses data after editing
            _loadBudget();
            setState(() {
              _refreshCounter++;
            });
          },
          isEditingTemplate:
              false, // We're editing the actual budget, not the template
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'ExpensesScreen: build called, selectedMonth: $_selectedMonth, refreshCounter: $_refreshCounter, _isScreenInitialized: $_isScreenInitialized');

    if (!_isScreenInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: const CenterLoadingWidget(radius: 16.0),
      );
    }

    // Check if we have a primary wallet
    final primaryWallet = _walletService.getPrimaryWallet();
    print('ExpensesScreen: build - primaryWallet: $primaryWallet');

    if (primaryWallet == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 16.0, 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Expenses & Budget',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildNoWalletView(),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FutureBuilder<List<CategoryMonthlySummary>>(
          key: ValueKey<String>('categories_$_refreshCounter'),
          future: _expenseService.getExpensesByCategory(_selectedMonth),
          builder: (context, snapshot) {
            print(
                'ExpensesScreen: Categories FutureBuilder (key: categories_$_refreshCounter) - month: $_selectedMonth, state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print(
                  'ExpensesScreen: Error in first FutureBuilder: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_circle,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading expense categories: ${snapshot.error}'),
                  ],
                ),
              );
            }

            final List<CategoryMonthlySummary> categorySummaries =
                snapshot.data ?? [];

            return FutureBuilder<double>(
              key: ValueKey<String>('total_$_refreshCounter'),
              future: _expenseService.getTotalForMonth(_selectedMonth),
              builder: (context, totalSnapshot) {
                print(
                    'ExpensesScreen: Total FutureBuilder (key: total_$_refreshCounter) - month: $_selectedMonth, state: ${totalSnapshot.connectionState}, hasData: ${totalSnapshot.hasData}, hasError: ${totalSnapshot.hasError}');

                if (totalSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (totalSnapshot.hasError) {
                  print(
                      'ExpensesScreen: Error in second FutureBuilder: ${totalSnapshot.error}');
                  return Center(child: Text('Error: ${totalSnapshot.error}'));
                }

                if (!totalSnapshot.hasData) {
                  return const Center(child: Text('No total data available'));
                }

                final totalSpent = totalSnapshot.data!;
                final budget = primaryWallet.budget ?? 0.0;
                final remainingBudget = budget - totalSpent;

                print(
                    'ExpensesScreen: totalSpent: $totalSpent, budget: $budget, remainingBudget: $remainingBudget');

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clean header with logo and add button
                      Container(
                        padding:
                            const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                        color:
                            const Color(0xFFF8F9FA), // Match background color
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Seva Finance Logo
                            Text(
                              'SevaFinance',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B4332),
                                letterSpacing: -0.5,
                              ),
                            ),
                            // Debug and Add buttons
                            Row(
                              children: [
                                // Debug button for coach tips (temporary)
                                IconButton(
                                  icon: const Icon(CupertinoIcons.lightbulb),
                                  color: const Color(0xFF1B4332),
                                  iconSize: 24,
                                  onPressed: () async {
                                    try {
                                      await _coachService.forceGenerateTips();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Coach tips generated!'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      print('Error generating tips: $e');
                                    }
                                  },
                                ),
                                // Add button
                                IconButton(
                                  icon: const Icon(CupertinoIcons.plus_circle),
                                  color: const Color(0xFF1B4332),
                                  iconSize: 28,
                                  onPressed: _showAddOptions,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // My Spending Card - NEW
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isMySpendingLoading
                            ? const SizedBox(
                                height: 100,
                                child: CenterLoadingWidget(
                                    showText:
                                        false)) // Height matches approx card height
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Spending',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF4A4A4A),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatCurrency(_currentWeekTotal),
                                            style: GoogleFonts.inter(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF1C1C1E),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (_spendingTrend != 0 ||
                                                  _currentWeekTotal > 0) ...[
                                                Icon(
                                                  _spendingTrend >= 0
                                                      ? CupertinoIcons.arrow_up
                                                      : CupertinoIcons
                                                          .arrow_down,
                                                  color: _spendingTrend >= 0
                                                      ? const Color(0xFF34C759)
                                                      : Colors.red,
                                                  size: 14,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  '${(_spendingTrend * 100).abs().toStringAsFixed(1)}% ',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color: _spendingTrend >= 0
                                                        ? const Color(
                                                            0xFF34C759)
                                                        : Colors.red,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'From last week',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color:
                                                        const Color(0xFF8E8E93),
                                                  ),
                                                ),
                                              ] else ...[
                                                Text(
                                                  'No spending last week',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    color:
                                                        const Color(0xFF8E8E93),
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Mini Bar Chart
                                      Container(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: List.generate(7, (index) {
                                            final dayLabels = [
                                              'M',
                                              'T',
                                              'W',
                                              'T',
                                              'F',
                                              'S',
                                              'S'
                                            ]; // Mon to Sun
                                            final now = DateTime.now();
                                            // DateTime.weekday: 1=Mon, ..., 7=Sun. We want 0=Mon, ..., 6=Sun for index.
                                            final int currentDayIndex =
                                                now.weekday - 1;
                                            final bool isCurrentDay =
                                                index == currentDayIndex;
                                            final String dailyTotalStr =
                                                _dailyTotalsForChart
                                                            .isNotEmpty &&
                                                        index <
                                                            _dailyTotalsForChart
                                                                .length
                                                    ? _dailyTotalsForChart[
                                                            index]
                                                        .toStringAsFixed(2)
                                                    : 'N/A';

                                            // Log the values for each bar being generated
                                            print(
                                                'MySpendingChart: index=$index (${dayLabels[index]}), currentDayRaw=${now.weekday}, currentDayIndexCalcd=$currentDayIndex, isCurrent=$isCurrentDay, total=$dailyTotalStr');

                                            const double maxBarHeight = 22.0;
                                            double barHeight = 0;
                                            if (_dailyTotalsForChart
                                                    .isNotEmpty &&
                                                _dailyTotalsForChart
                                                    .any((d) => d > 0)) {
                                              final double maxDailySpending =
                                                  _dailyTotalsForChart.reduce(
                                                      (a, b) => a > b ? a : b);
                                              if (maxDailySpending > 0) {
                                                barHeight =
                                                    (_dailyTotalsForChart[
                                                                index] /
                                                            maxDailySpending) *
                                                        maxBarHeight;
                                              }
                                            }
                                            // Ensure barHeight is not NaN and is at least a minimal visible height if > 0
                                            barHeight =
                                                barHeight.isNaN ? 0 : barHeight;
                                            if (_dailyTotalsForChart[index] >
                                                    0 &&
                                                barHeight < 2) barHeight = 2;

                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 3.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    height: barHeight,
                                                    width: 8,
                                                    decoration: BoxDecoration(
                                                      color: isCurrentDay
                                                          ? const Color(
                                                              0xFF34C759) // Brighter/solid for current day
                                                          : (_dailyTotalsForChart
                                                                      .isNotEmpty &&
                                                                  _dailyTotalsForChart[
                                                                          index] >
                                                                      0
                                                              ? const Color(
                                                                      0xFF34C759)
                                                                  .withOpacity(
                                                                      0.6) // Slightly more opaque for days with spending
                                                              : const Color(
                                                                      0xFF34C759)
                                                                  .withOpacity(
                                                                      0.25)), // Default for no spending
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              2),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    dayLabels[index],
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: isCurrentDay
                                                          ? const Color(
                                                              0xFF1C1C1E)
                                                          : const Color(
                                                              0xFF8E8E93), // Darker for current day label
                                                      fontWeight: isCurrentDay
                                                          ? FontWeight.w600
                                                          : FontWeight
                                                              .normal, // Bolder for current day label
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      // END My Spending Card

                      // AI Coach Tips Section
                      Consumer<CoachService>(
                        builder: (context, coachService, child) {
                          // Load tips when first building, but only if not already loading
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (coachService.tips.isEmpty &&
                                !coachService.isLoading &&
                                mounted) {
                              try {
                                coachService
                                    .forceGenerateTips(); // Use force generate for testing
                              } catch (e) {
                                print('Error generating coach tips: $e');
                                // Silently fail - don't show error to user
                              }
                            }
                          });

                          try {
                            final unreadTips = coachService.unreadTips;
                            if (unreadTips.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            // Show the highest priority tip
                            final topTip = unreadTips.first;

                            return CoachCard(
                              tip: topTip,
                              onDismiss: () async {
                                try {
                                  await _dismissTip(topTip);
                                } catch (e) {
                                  print('Error dismissing tip: $e');
                                }
                              },
                              onLearnMore: topTip.actionText != null
                                  ? () => _handleCoachAction(topTip)
                                  : null,
                            );
                          } catch (e) {
                            print('Error in coach tips UI: $e');
                            return const SizedBox.shrink();
                          }
                        },
                      ),

                      // Category Budget Tracker
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: CategoryBudgetTracker(
                          walletId: primaryWallet.id,
                          month: _selectedMonth,
                          onMonthChanged: (newMonth) {
                            setState(() {
                              _selectedMonth = newMonth;
                            });
                            _loadMySpendingData();
                            _loadSixMonthChartData();
                          },
                          onChooseTemplate: _showTemplatePickerModal,
                          onEditBudget: _editCurrentBudget,
                        ),
                      ),

                      // New "Expense" Card with Line Chart and Category List
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16.0, bottom: 0.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Expense',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF3C3C43),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '-${_formatCurrency(totalSpent.abs())}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1C1C1E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFFD1D1D6),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      DateFormat('MMM yyyy')
                                          .format(_selectedMonth),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF3C3C43),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Line/Area Chart - Placeholder or Real Data
                            _isSixMonthChartLoading
                                ? const SizedBox(
                                    height: 120, // Match chart height
                                    child: CenterLoadingWidget(showText: false),
                                  )
                                : Container(
                                    height: 120,
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 0, right: 16, left: 8),
                                    child: _sixMonthChartSpots.isEmpty
                                        ? Center(
                                            child: Text(
                                              'No spending data for chart.',
                                              style: GoogleFonts.inter(
                                                  color: Colors.grey[600]),
                                            ),
                                          )
                                        : LineChart(
                                            LineChartData(
                                              gridData:
                                                  const FlGridData(show: false),
                                              titlesData: FlTitlesData(
                                                leftTitles: const AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false)),
                                                topTitles: const AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false)),
                                                rightTitles: const AxisTitles(
                                                    sideTitles: SideTitles(
                                                        showTitles: false)),
                                                bottomTitles: AxisTitles(
                                                  sideTitles: SideTitles(
                                                    showTitles: true,
                                                    reservedSize: 30,
                                                    interval:
                                                        1, // Show all month labels
                                                    getTitlesWidget:
                                                        (double value,
                                                            TitleMeta meta) {
                                                      const style = TextStyle(
                                                        fontFamily: 'Inter',
                                                        color:
                                                            Color(0xFF8E8E93),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 12,
                                                      );
                                                      // value corresponds to the index in _sixMonthChartLabels
                                                      final index =
                                                          value.toInt();
                                                      if (index >= 0 &&
                                                          index <
                                                              _sixMonthChartLabels
                                                                  .length) {
                                                        return Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 6.0),
                                                          child: Text(
                                                              _sixMonthChartLabels[
                                                                  index],
                                                              style: style,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center),
                                                        );
                                                      }
                                                      return const Text('');
                                                    },
                                                  ),
                                                ),
                                              ),
                                              borderData:
                                                  FlBorderData(show: false),
                                              minX: 0,
                                              // maxX should be the number of spots - 1
                                              maxX:
                                                  _sixMonthChartSpots.isNotEmpty
                                                      ? (_sixMonthChartSpots
                                                                  .length -
                                                              1)
                                                          .toDouble()
                                                      : 0,
                                              minY: 0,
                                              maxY:
                                                  _maxSixMonthSpending, // NEW: Use new max Y value
                                              lineBarsData: [
                                                LineChartBarData(
                                                  spots:
                                                      _sixMonthChartSpots, // NEW: Use new spots list
                                                  isCurved: true,
                                                  curveSmoothness:
                                                      0.35, // Smooth curve
                                                  color:
                                                      const Color(0xFF34C759),
                                                  barWidth: 2.5,
                                                  isStrokeCapRound: true,
                                                  dotData: FlDotData(
                                                    show: true,
                                                    getDotPainter: (spot,
                                                        percent,
                                                        barData,
                                                        index) {
                                                      // Highlight the last dot (current month)
                                                      final isLastDot = index ==
                                                          _sixMonthChartSpots
                                                                  .length -
                                                              1;
                                                      return FlDotCirclePainter(
                                                        radius:
                                                            isLastDot ? 4 : 3,
                                                        color: const Color(
                                                                0xFF34C759)
                                                            .withOpacity(
                                                                isLastDot
                                                                    ? 1.0
                                                                    : 0.8),
                                                        strokeWidth:
                                                            isLastDot ? 1 : 0,
                                                        strokeColor:
                                                            Colors.white,
                                                      );
                                                    },
                                                  ),
                                                  belowBarData: BarAreaData(
                                                    show: true,
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(0xFF34C759)
                                                            .withOpacity(0.4),
                                                        const Color(0xFF34C759)
                                                            .withOpacity(0.1),
                                                      ],
                                                      begin:
                                                          Alignment.topCenter,
                                                      end: Alignment
                                                          .bottomCenter,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              lineTouchData: LineTouchData(
                                                handleBuiltInTouches: true,
                                                getTouchedSpotIndicator:
                                                    (LineChartBarData barData,
                                                        List<int> spotIndexes) {
                                                  return spotIndexes
                                                      .map((index) {
                                                    return TouchedSpotIndicatorData(
                                                      const FlLine(
                                                        color:
                                                            Color(0xFFD1D1D6),
                                                        strokeWidth: 1,
                                                      ),
                                                      FlDotData(
                                                        getDotPainter: (spot,
                                                            percent,
                                                            barData,
                                                            index) {
                                                          return FlDotCirclePainter(
                                                            radius: 4,
                                                            color: const Color(
                                                                0xFF34C759),
                                                            strokeWidth: 1,
                                                            strokeColor:
                                                                Colors.white,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  }).toList();
                                                },
                                                touchTooltipData:
                                                    LineTouchTooltipData(
                                                  tooltipPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                  tooltipMargin: 8,
                                                  fitInsideHorizontally: true,
                                                  fitInsideVertically: true,
                                                  getTooltipItems:
                                                      (List<LineBarSpot>
                                                          touchedBarSpots) {
                                                    return touchedBarSpots
                                                        .map((barSpot) {
                                                      // Get month name from _sixMonthChartLabels using barSpot.spotIndex
                                                      final monthIndex =
                                                          barSpot.spotIndex;
                                                      String monthName = '';
                                                      if (monthIndex >= 0 &&
                                                          monthIndex <
                                                              _sixMonthChartLabels
                                                                  .length) {
                                                        monthName =
                                                            _sixMonthChartLabels[
                                                                monthIndex];
                                                      }
                                                      return LineTooltipItem(
                                                        '$monthName: ${_formatCurrency(barSpot.y)}', // Show month name in tooltip
                                                        const TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.black,
                                                        ),
                                                      );
                                                    }).toList();
                                                  },
                                                ),
                                                touchCallback:
                                                    (FlTouchEvent event,
                                                        LineTouchResponse?
                                                            touchResponse) {
                                                  // Handle touch events if needed
                                                },
                                              ),
                                            ),
                                          ),
                                  ),
                            const SizedBox(height: 12),

                            // Row for "Categories" title and "View All" button
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Categories',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RecentExpensesScreen(
                                            expenseService: _expenseService,
                                          ),
                                        ),
                                      ).then((_) => _refreshScreen());
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      alignment: Alignment.centerRight,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'View All',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF1B4332),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          CupertinoIcons.arrow_right_circle,
                                          size: 16,
                                          color: Color(0xFF1B4332),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Display real category data or a message if no expenses
                            if (categorySummaries.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'No expenses for ${DateFormat('MMMM').format(_selectedMonth)} yet.',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...categorySummaries.map((summary) {
                                return _buildCategoryListItem(
                                    summary.categoryId,
                                    summary.categoryName,
                                    summary.totalAmount);
                              }).toList(),
                          ],
                        ),
                      ),
                      // END New "Expense" Card

                      const SizedBox(
                          height: 80), // Added smaller SizedBox for FAB spacing
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF40916C),
              Color(0xFF1B4332),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4332).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'scan_receipt',
          onPressed: () async {
            // Navigate to OcrScreen and handle result
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OcrScreen()),
            );
            // If expense was saved, refresh the screen
            if (result == true) {
              _refreshScreen();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: const Row(
            children: [
              Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Scan Receipt',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for category list item (NEW - add this at the end of the class or in a helpers file)
  Widget _buildCategoryListItem(
      String categoryId, String categoryName, double amount) {
    final categoryIcon = _categoryIcons[categoryName] ??
        _categoryIcons['Other'] ??
        CupertinoIcons.square_grid_2x2;

    return InkWell(
      onTap: () async {
        final List<Expense> expensesForMonth =
            await _expenseService.getExpensesForMonth(_selectedMonth);
        final List<Expense> categorySpecificExpenses = expensesForMonth
            .where((expense) => expense.categoryId == categoryId)
            .toList();

        if (categorySpecificExpenses.length == 1) {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailScreen(
                expense: categorySpecificExpenses.first,
                expenseService: _expenseService,
                onExpenseUpdated: _refreshScreen,
              ),
            ),
          );
          _refreshScreen();
        } else {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecentExpensesScreen(
                expenseService: _expenseService,
                categoryForMonthFilter: categoryId,
                monthForCategoryFilter: _selectedMonth,
              ),
            ),
          );
          _refreshScreen();
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(categoryIcon, size: 18, color: const Color(0xFF007A3D)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Color(0xFF1C1C1E),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Text(
              _formatCurrency(amount),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
