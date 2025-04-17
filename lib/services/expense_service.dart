import '../models/expense.dart';
import 'storage_service.dart';
import 'wallet_service.dart';
import 'package:hive/hive.dart';
import 'notification_service.dart';

class ExpenseService {
  final StorageService _storageService;
  final Box<double> _budgetBox;
  final Box<Expense> _expenseBox;
  final WalletService _walletService;
  final NotificationService _notificationService;

  ExpenseService(this._storageService, this._budgetBox, this._expenseBox, this._walletService, this._notificationService);

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    return await _storageService.getAllExpenses();
  }

  // Get all expenses for a specific month
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _expenseBox.values.where((expense) {
      return expense.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
             expense.date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
    }).toList();
  }

  // Get total amount spent in a specific month
  Future<double> getTotalForMonth(DateTime month) async {
    final expenses = await getExpensesForMonth(month);
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get expenses by category for a specific month
  Future<Map<String, double>> getExpensesByCategory(DateTime month) async {
    final expenses = await getExpensesForMonth(month);
    final categoryTotals = <String, double>{};
    
    for (final expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    
    return categoryTotals;
  }

  // Add a new expense
  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    _notificationService.addActionNotification(
      title: 'New Expense Added',
      message: '${expense.amount} spent on ${expense.category}',
      relatedId: expense.id,
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    final expense = _expenseBox.get(expenseId);
    if (expense != null) {
      await _expenseBox.delete(expenseId);
      _notificationService.addActionNotification(
        title: 'Expense Deleted',
        message: '${expense.amount} removed from ${expense.category}',
      );
    }
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    _notificationService.addActionNotification(
      title: 'Expense Updated',
      message: '${expense.amount} updated for ${expense.category}',
      relatedId: expense.id,
    );
  }

  // Get expenses for previous month (for trend calculation)
  Future<Map<String, double>> getExpensesForPreviousMonth(DateTime currentMonth) async {
    final previousMonth = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
      currentMonth.day,
    );
    return getExpensesByCategory(previousMonth);
  }

  // Calculate trend percentage for a category
  Future<double> calculateTrend() async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    
    final currentMonthTotal = await getTotalForMonth(now);
    final lastMonthTotal = await getTotalForMonth(lastMonth);
    
    if (lastMonthTotal == 0) return 0;
    return ((currentMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
  }

  Future<double> getBudget() async {
    final primaryWallet = _walletService.getPrimaryWallet();
    return primaryWallet?.budget ?? 0.0;
  }

  Future<void> setBudget(double budget) async {
    final primaryWallet = _walletService.getPrimaryWallet();
    if (primaryWallet != null) {
      await _walletService.setWalletBudget(primaryWallet.id, budget);
    }
  }

  Future<List<Expense>> getExpenses() async {
    return _expenseBox.values.toList();
  }

  Future<double> getTotalExpenses() async {
    final expenses = await getExpenses();
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<double> getRemainingBudget() async {
    final budget = await getBudget();
    final totalExpenses = await getTotalExpenses();
    return budget - totalExpenses;
  }

  Future<Map<String, List<Expense>>> getExpensesByTimeline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final groupedExpenses = {
      'Today': <Expense>[],
      'This Week': <Expense>[],
      'Earlier': <Expense>[],
    };

    final expenses = await getExpenses();
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

  // Add alert notification when budget is exceeded
  Future<void> checkBudgetExceeded(String walletId, double amount) async {
    final wallet = _budgetBox.get(walletId);
    if (wallet != null && wallet > 0) {
      final monthlyExpenses = await getExpensesForMonth(DateTime.now());
      final totalSpent = monthlyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      if (totalSpent + amount > wallet) {
        _notificationService.addAlertNotification(
          alertId: walletId,
          title: 'Budget Alert',
          message: 'This expense will exceed your monthly budget',
        );
      }
    }
  }
} 