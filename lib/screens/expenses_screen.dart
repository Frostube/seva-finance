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
import '../services/budget_service.dart';
import 'add_budget_screen.dart';
import 'remove_budget_screen.dart';
import 'recent_expenses_screen.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'package:hive/hive.dart';
import '../services/wallet_service.dart';
import 'edit_wallet_screen.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // Color palette for pie chart - more distinguishable pastels
  static const pieColors = [
    Color(0xFF40916C), // Main green
    Color(0xFF9EC1A3), // Sage green
    Color(0xFFCFE1B9), // Light mint
    Color(0xFFE9F1EC), // Pale green
  ];

  late ExpenseService _expenseService;
  late WalletService _walletService;
  double? _monthlyBudget;
  final String _searchQuery = '';
  double _cachedTotalSpent = 0.0;
  Map<String, double> _cachedExpensesByCategory = {};
  double _cachedBudgetUsage = 0.0;
  late final BudgetService _budgetService;
  late StreamSubscription<BoxEvent> _walletBoxSubscription;

  // Add selectedMonth state
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

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

  final Map<String, double> _lastMonthSpending = {
    'Rent': 1485.00,
    'Groceries': 140.00,
    'Transport': 35.00,
    'Shopping': 71.00,
  };

  @override
  void initState() {
    super.initState();
    print('ExpensesScreen: initState called');
    _expenseService = ExpenseService(
      Provider.of<StorageService>(context, listen: false),
      Hive.box<double>('budget'),
      Hive.box<Expense>('expenses'),
      Provider.of<WalletService>(context, listen: false),
      Provider.of<NotificationService>(context, listen: false),
      Provider.of<FirebaseFirestore>(context, listen: false),
      Provider.of<FirebaseStorage>(context, listen: false),
    );
    _walletService = Provider.of<WalletService>(context, listen: false);
    _budgetService = BudgetService(Hive.box<double>('budget'));
    _loadBudget();
    
    // Listen for wallet changes
    _walletBoxSubscription = Hive.box<Wallet>('wallets').watch().listen((event) {
      _loadBudget();
    });
  }

  @override
  void dispose() {
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
                  createdAt: DateTime.now().toString().split(' ')[0],
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.plus_circle_fill, color: Colors.white),
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
    print('ExpensesScreen: _loadBudget called');
    final primaryWallet = _walletService.getPrimaryWallet();
    print('ExpensesScreen: primaryWallet: $primaryWallet');
    
    setState(() {
      _monthlyBudget = primaryWallet?.budget ?? 0.0;
    });
    print('ExpensesScreen: _monthlyBudget set to: $_monthlyBudget');
    await _updateCachedValues();
  }

  Future<void> _updateCachedValues() async {
    print('ExpensesScreen: Updating cached values for ${DateFormat('MMMM yyyy').format(_selectedMonth)}');
    _cachedTotalSpent = await _expenseService.getTotalForMonth(_selectedMonth);
    _cachedExpensesByCategory = await _expenseService.getExpensesByCategory(_selectedMonth);
    final primaryWallet = _walletService.getPrimaryWallet();
    if (primaryWallet != null && primaryWallet.budget != null && primaryWallet.budget! > 0) {
      _cachedBudgetUsage = _cachedTotalSpent / primaryWallet.budget!;
    } else {
      _cachedBudgetUsage = 0.0;
    }
    setState(() {});
  }

  Future<double> _totalSpent() async {
    final expenses = await _expenseService.getExpenses();
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  double get _remainingBudget => _monthlyBudget != null ? _monthlyBudget! - _cachedTotalSpent : 0.0;
  double get _budgetUsagePercentage => _monthlyBudget != null && _monthlyBudget! > 0 ? _cachedBudgetUsage : 0.0;

  Future<Map<String, double>> _currentExpenses() async {
    final expenses = await _expenseService.getExpenses();
    final categoryTotals = <String, double>{};
    
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    
    return categoryTotals;
  }

  Future<double> _calculateTrend() async {
    final currentMonthExpenses = await _expenseService.getExpenses();
    final previousMonth = DateTime.now().subtract(Duration(days: DateTime.now().day - 1));
    final previousMonthExpenses = await _expenseService.getExpensesForMonth(previousMonth);

    final currentTotal = currentMonthExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    final previousTotal = previousMonthExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);

    if (previousTotal == 0) return 0;
    
    final trendPercentage = ((currentTotal - previousTotal) / previousTotal) * 100;
    return trendPercentage.isFinite ? trendPercentage.clamp(-100.0, double.infinity) : 0.0;
  }

  Future<Map<String, List<Expense>>> _groupExpensesByTimeline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final groupedExpenses = {
      'Today': <Expense>[],
      'This Week': <Expense>[],
      'Earlier': <Expense>[],
    };

    final expenses = await _expenseService.getExpenses();
    expenses.sort((a, b) => b.date.compareTo(a.date));

    for (var expense in expenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      if (expenseDate == today) {
        groupedExpenses['Today']!.add(expense);
      } else if (expenseDate.isAfter(startOfWeek)) {
        groupedExpenses['This Week']!.add(expense);
      } else {
        groupedExpenses['Earlier']!.add(expense);
      }
    }

    return groupedExpenses;
  }

  Future<List<Expense>> _filterExpenses(String category) async {
    final expenses = await _expenseService.getExpenses();
    if (_searchQuery.isEmpty && (category == 'All')) {
      return expenses;
    }

    return expenses.where((expense) =>
      (category == 'All' || expense.category == category) &&
      (_searchQuery.isEmpty || 
        expense.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (expense.note?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase()) ||
        expense.amount.toString().contains(_searchQuery))
    ).toList();
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    Text(
                      'Select Month',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pop(context);
                        _updateCachedValues();
                      },
                      child: Text(
                        'Done',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1B4332),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedMonth,
                  minimumYear: 2020,
                  maximumYear: DateTime.now().year,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedMonth = DateTime(newDate.year, newDate.month);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isCurrentMonth() {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _navigateMonth(int monthDelta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + monthDelta,
      );
      _updateCachedValues(); // Reload data for new month
    });
  }

  void _refreshScreen() {
    setState(() {});
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: '\$',
      decimalDigits: amount.truncateToDouble() == amount ? 0 : 2,
    ).format(amount);
  }

  Widget _buildTopCategoryItem({
    required IconData icon,
    required String label,
    required String amount,
    required double trend,
  }) {
    return SizedBox(
      width: 85, // Reduced from 100 to prevent overflow
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8), // Reduced from 10
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1B4332),
              size: 18, // Reduced from 20
            ),
          ),
          const SizedBox(height: 4), // Reduced from 6
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11, // Reduced from 12
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: GoogleFonts.inter(
                fontSize: 12, // Reduced from 13
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trend != 0) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  trend > 0 
                      ? CupertinoIcons.arrow_up
                      : CupertinoIcons.arrow_down,
                  size: 10,
                  color: trend > 0 ? Colors.red : Colors.green,
                ),
                Text(
                  '${(trend * 100).abs().toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 9, // Reduced from 10
                    color: trend > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseItem({
    required IconData icon,
    required String title,
    required String date,
    required double amount,
    required Color iconBackgroundColor,
    bool showTrend = false,
    double trendPercentage = 0,
    required Expense expense,
  }) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => TransactionDetailScreen(
              expense: expense,
              expenseService: _expenseService,
              onExpenseUpdated: _refreshScreen,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1B4332),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(amount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (showTrend && trendPercentage != 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendPercentage > 0 
                            ? CupertinoIcons.arrow_up
                            : CupertinoIcons.arrow_down,
                        size: 12,
                        color: trendPercentage > 0 ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${trendPercentage.abs().toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: trendPercentage > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String category,
    required double amount,
    required Color color,
    required IconData icon,
    required double trend,
    required Expense expense,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  expense.note!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    _formatCurrency(amount),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (trend != 0) ...[
                    const SizedBox(width: 4),
                    Icon(
                      trend > 0 
                          ? CupertinoIcons.arrow_up
                          : CupertinoIcons.arrow_down,
                      size: 10,
                      color: trend > 0 ? Colors.red : Colors.green,
                    ),
                    Text(
                      '${(trend * 100).abs().toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: trend > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
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
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: (context) => AddExpenseScreen(
                          expenseService: _expenseService,
                          onExpenseAdded: _refreshScreen,
                        ),
                      ),
                    );
                    if (result == true) {
                      _refreshScreen();
                    }
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

  Widget _buildBudgetText() {
    final formatter = NumberFormat.currency(symbol: '\$');
    return GestureDetector(
      onTap: _showAddBudgetScreen,
      child: Row(
        children: [
          Text(
            'You have ${formatter.format(_remainingBudget)} left for ${DateFormat('MMMM').format(DateTime.now())}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF40916C),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            CupertinoIcons.pencil,
            size: 12,
            color: Color(0xFF40916C),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensePreviewItem(Expense expense) {
    final formatter = NumberFormat.currency(symbol: '\$');
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => TransactionDetailScreen(
              expense: expense,
              expenseService: _expenseService,
              onExpenseUpdated: _refreshScreen,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _categoryIcons[expense.category] ?? CupertinoIcons.square_grid_2x2,
                color: const Color(0xFF1B4332),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (expense.note != null && expense.note!.isNotEmpty)
                    Text(
                      expense.note!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(expense.amount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(expense.date),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensePreviewSection(String title, List<Expense> expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        ...expenses.take(2).map((expense) => _buildExpensePreviewItem(expense)),
      ],
    );
  }

  Widget _buildRecentExpensesPreview() {
    return FutureBuilder<Map<String, List<Expense>>>(
      future: _groupExpensesByTimeline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final groupedExpenses = snapshot.data ?? {
          'Today': [],
          'This Week': [],
          'Earlier': [],
        };

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Expenses',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecentExpensesScreen(
                            expenseService: _expenseService,
                          ),
                        ),
                      ).then((_) => _refreshScreen());
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              const SizedBox(height: 16),
              if (groupedExpenses.values.every((list) => list.isEmpty))
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No expenses for this month',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
              else ...[
                _buildExpensePreviewSection('Today', groupedExpenses['Today']!),
                if (groupedExpenses['Today']!.isNotEmpty)
                  const Divider(height: 32),
                _buildExpensePreviewSection('This Week', groupedExpenses['This Week']!),
                if (groupedExpenses['This Week']!.isNotEmpty)
                  const Divider(height: 32),
                _buildExpensePreviewSection('Earlier', groupedExpenses['Earlier']!),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ExpensesScreen: build called');
    final formatter = NumberFormat.currency(symbol: '\$');
    final isCurrentMonth = _isCurrentMonth();

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
                          fontSize: 28,
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
        child: FutureBuilder<Map<String, double>>(
          future: _expenseService.getExpensesByCategory(_selectedMonth),
          builder: (context, snapshot) {
            print('ExpensesScreen: First FutureBuilder - state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('ExpensesScreen: Error in first FutureBuilder: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_circle, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading expenses: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('No expense data available'));
            }

            final currentExpenses = snapshot.data!;
            
            // Handle empty expenses
            if (currentExpenses.isEmpty) {
              currentExpenses['No expenses'] = 0.0;
            }

            return FutureBuilder<double>(
              future: _expenseService.getTotalForMonth(_selectedMonth),
              builder: (context, totalSnapshot) {
                print('ExpensesScreen: Second FutureBuilder - state: ${totalSnapshot.connectionState}, hasData: ${totalSnapshot.hasData}, hasError: ${totalSnapshot.hasError}');
                
                if (totalSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (totalSnapshot.hasError) {
                  print('ExpensesScreen: Error in second FutureBuilder: ${totalSnapshot.error}');
                  return Center(child: Text('Error: ${totalSnapshot.error}'));
                }

                if (!totalSnapshot.hasData) {
                  return const Center(child: Text('No total data available'));
                }

                final totalSpent = totalSnapshot.data!;
                final budget = primaryWallet.budget ?? 0.0;
                final remainingBudget = budget - totalSpent;
                final budgetUsagePercentage = budget > 0 
                    ? (totalSpent / budget).clamp(0.0, 1.0)
                    : 0.0;

                print('ExpensesScreen: totalSpent: $totalSpent, budget: $budget, remainingBudget: $remainingBudget, budgetUsagePercentage: $budgetUsagePercentage');

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with integrated budget view
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Expenses & Budget',
                                    style: GoogleFonts.inter(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(CupertinoIcons.plus_circle),
                                  color: const Color(0xFF1B4332),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: _showAddOptions,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Add wallet balance line
                            Text(
                              'Balance: ${formatter.format(primaryWallet.balance)}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(CupertinoIcons.chevron_left, size: 20),
                                  onPressed: () => _navigateMonth(-1),
                                  color: Colors.grey[600],
                                ),
                                GestureDetector(
                                  onTap: _showMonthPicker,
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(_selectedMonth),
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (!isCurrentMonth)
                                  IconButton(
                                    icon: const Icon(CupertinoIcons.chevron_right, size: 20),
                                    onPressed: () => _navigateMonth(1),
                                    color: Colors.grey[600],
                                  ),
                                if (isCurrentMonth)
                                  const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatter.format(totalSpent),
                                  style: GoogleFonts.inter(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    primaryWallet.budget != null && primaryWallet.budget! > 0
                                        ? 'of ${formatter.format(primaryWallet.budget!)}'
                                        : 'No budget set',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: primaryWallet.budget != null && primaryWallet.budget! > 0
                                    ? (totalSpent / primaryWallet.budget!).clamp(0.0, 1.0)
                                    : 0.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF40916C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _showAddBudgetScreen,
                              child: Row(
                                children: [
                                  Text(
                                    primaryWallet.budget != null && primaryWallet.budget! > 0
                                        ? 'You have ${formatter.format(primaryWallet.budget! - totalSpent)} left for ${DateFormat('MMMM').format(_selectedMonth)}'
                                        : 'Tap to set a monthly budget',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF40916C),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    CupertinoIcons.pencil,
                                    size: 12,
                                    color: Color(0xFF40916C),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // AI Tip Banner with carousel dots
                      Container(
                        margin: const EdgeInsets.all(24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F1EC),
                            borderRadius: BorderRadius.circular(16),
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
                              const Icon(
                                CupertinoIcons.lightbulb,
                                color: Color(0xFF1B4332),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tip: Your grocery spending is 15% higher than last month',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFF1B4332),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Spending Breakdown with improved chart
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spending Breakdown',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _showMonthPicker,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    CupertinoIcons.calendar_today,
                                    size: 20,
                                    color: Color(0xFF1B4332),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 180,
                                  width: 180,
                                  child: Stack(
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sections: currentExpenses.entries.map((entry) {
                                            final index = currentExpenses.keys.toList().indexOf(entry.key);
                                            return PieChartSectionData(
                                              value: entry.value,
                                              color: pieColors[index % pieColors.length],
                                              radius: 40,
                                              showTitle: false,
                                            );
                                          }).toList(),
                                          sectionsSpace: 0,
                                          centerSpaceRadius: 40,
                                        ),
                                      ),
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Total',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _formatCurrency(totalSpent),
                                              style: GoogleFonts.inter(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    for (var entry in currentExpenses.entries)
                                      _buildCategoryChip(
                                        category: entry.key,
                                        amount: entry.value,
                                        color: pieColors[currentExpenses.keys.toList().indexOf(entry.key) % pieColors.length],
                                        icon: _categoryIcons[entry.key] ?? CupertinoIcons.money_dollar_circle,
                                        trend: 0.0, // Default trend value
                                        expense: Expense(
                                          id: 'default',
                                          amount: entry.value,
                                          category: entry.key,
                                          date: DateTime.now(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                "You're on track this month — ${(remainingBudget / budget * 100).toStringAsFixed(0)}% of budget remaining!",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF40916C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recent Expenses Preview
                      _buildRecentExpensesPreview(),

                      const SizedBox(height: 100), // Space for FAB
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
          onPressed: () {},
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: Row(
            children: [
              const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Scan Receipt',
                style: GoogleFonts.inter(
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
} 