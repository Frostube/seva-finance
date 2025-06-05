import '../models/expense.dart';
import 'storage_service.dart';
import 'wallet_service.dart';
import 'package:hive/hive.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Helper class for category summary
class CategoryMonthlySummary {
  final String categoryName;
  final double totalAmount;
  final DateTime latestTransactionDateInMonth;

  CategoryMonthlySummary({
    required this.categoryName,
    required this.totalAmount,
    required this.latestTransactionDateInMonth,
  });
}

class ExpenseService with ChangeNotifier {
  final StorageService _storageService;
  final Box<double> _budgetBox;
  final Box<Expense> _expenseBox;
  final WalletService _walletService;
  final NotificationService _notificationService;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  ExpenseService(this._storageService, this._budgetBox, this._expenseBox, this._walletService, this._notificationService, this._firestore, this._storage) {
    _initialLoadFuture = _loadExpenses();
  }

  Future<void>? get initializationComplete => _initialLoadFuture;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load from local storage first
      _expenses = _expenseBox.values.toList();

      // Then sync with Firestore
      final snapshot = await _firestore.collection('expenses')
          .where('userId', isEqualTo: _userId)
          .get();
      final remoteExpenses = snapshot.docs.map((doc) {
        final data = doc.data();
        return Expense(
          id: doc.id,
          amount: data['amount'] as double,
          category: data['category'] as String,
          date: DateTime.parse(data['date'] as String),
          note: data['note'] as String?,
        );
      }).toList();

      // Merge local and remote expenses
      for (final remoteExpense in remoteExpenses) {
        final localIndex = _expenses.indexWhere((e) => e.id == remoteExpense.id);
        if (localIndex >= 0) {
          _expenses[localIndex] = remoteExpense;
        } else {
          _expenses.add(remoteExpense);
        }
      }

      // Save merged expenses to local storage
      await _expenseBox.clear();
      for (final expense in _expenses) {
        await _expenseBox.put(expense.id, expense);
      }
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    return await _storageService.getAllExpenses();
  }

  // Get all expenses for a specific month
  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    print('ExpenseService: getExpensesForMonth called for month: $month. Internal _expenses count: ${_expenses.length}');
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    // Filter the internal _expenses list, which is updated by add/delete/update operations
    final filteredExpenses = _expenses.where((expense) {
      return expense.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
             expense.date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
    }).toList();
    print('ExpenseService: getExpensesForMonth for $month returning ${filteredExpenses.length} items.');
    return filteredExpenses; // Directly return the synchronously filtered list
  }

  // Get total amount spent in a specific month
  Future<double> getTotalForMonth(DateTime month) async {
    final expenses = await getExpensesForMonth(month);
    return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get expenses by category for a specific month, sorted by recency
  Future<List<CategoryMonthlySummary>> getExpensesByCategory(DateTime month) async {
    print('ExpenseService: getExpensesByCategory called for $month');
    final expensesForMonth = await getExpensesForMonth(month);

    if (expensesForMonth.isEmpty) {
      print('ExpenseService: No expenses found for $month. Returning empty list.');
      return [];
    }

    final Map<String, Map<String, dynamic>> categoryData = {};

    for (final expense in expensesForMonth) {
      if (!categoryData.containsKey(expense.category)) {
        categoryData[expense.category] = {
          'total': 0.0,
          // Initialize with a very old date to ensure first expense.date is picked
          'latestDate': DateTime(1900), 
        };
      }
      categoryData[expense.category]!['total'] = 
          (categoryData[expense.category]!['total'] as double) + expense.amount;
      
      if (expense.date.isAfter(categoryData[expense.category]!['latestDate'] as DateTime)) {
        categoryData[expense.category]!['latestDate'] = expense.date;
      }
    }
    
    final List<CategoryMonthlySummary> summaries = categoryData.entries.map((entry) {
      return CategoryMonthlySummary(
        categoryName: entry.key,
        totalAmount: entry.value['total'] as double,
        latestTransactionDateInMonth: entry.value['latestDate'] as DateTime,
      );
    }).toList();

    // Sort by latestTransactionDateInMonth (descending), then by totalAmount (descending) as a tie-breaker
    summaries.sort((a, b) {
      int dateCompare = b.latestTransactionDateInMonth.compareTo(a.latestTransactionDateInMonth);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return b.totalAmount.compareTo(a.totalAmount); // Secondary sort by amount if dates are same
    });
    
    print('ExpenseService: getExpensesByCategory for $month returning ${summaries.length} summaries, sorted.');
    return summaries;
  }

  // New method for 6-month summary
  Future<Map<String, dynamic>> getMonthlyExpenseSummaryForLastSixMonths() async {
    print('ExpenseService: getMonthlyExpenseSummaryForLastSixMonths START');
    final List<FlSpot> spots = [];
    final List<String> monthLabels = [];
    double maxMonthlySpending = 0;

    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final totalForMonth = await getTotalForMonth(targetMonth);
      
      // The FlSpot x-value will be 0 for the earliest month, up to 5 for the current month.
      // So, for i=5 (earliest month), spotX is 0. For i=0 (current month), spotX is 5.
      final spotX = 5 - i.toDouble();
      spots.add(FlSpot(spotX, totalForMonth));
      monthLabels.add(DateFormat('MMM').format(targetMonth)); // e.g., "Jan", "Feb"

      if (totalForMonth > maxMonthlySpending) {
        maxMonthlySpending = totalForMonth;
      }
      print('ExpenseService: Month: ${DateFormat('MMM yyyy').format(targetMonth)}, Total: $totalForMonth, SpotX: $spotX');
    }
    print('ExpenseService: getMonthlyExpenseSummaryForLastSixMonths END - Spots: ${spots.length}, MaxSpending: $maxMonthlySpending');
    return {
      'spots': spots,
      'monthLabels': monthLabels,
      'maxSpending': maxMonthlySpending,
    };
  }

  // Add a new expense
  Future<void> addExpense(Expense expense) async {
    print('ExpenseService: addExpense START - Category: ${expense.category}, Amount: ${expense.amount}');
    try {
      _isLoading = true;
      notifyListeners();

      // Add to Firestore
      final docRef = await _firestore.collection('expenses').add({
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'note': expense.note,
        'userId': _userId,
      });

      // Update expense with Firestore ID
      final updatedExpense = Expense(
        id: docRef.id,
        amount: expense.amount,
        category: expense.category,
        date: expense.date,
        note: expense.note,
      );

      // Save to local storage
      await _expenseBox.put(updatedExpense.id, updatedExpense);
      print('ExpenseService: addExpense - Saved to _expenseBox. ID: ${updatedExpense.id}');
      _expenses.add(updatedExpense);
      print('ExpenseService: addExpense - Added to internal _expenses list. New count: ${_expenses.length}');

      _notificationService.addActionNotification(
        title: 'New Expense Added',
        message: '${expense.amount} spent on ${expense.category}',
        relatedId: expense.id,
      );

      _isLoading = false;
      notifyListeners();
      print('ExpenseService: addExpense END');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Grab the expense details before deleting so we can display them in
      // the notification after removal.
      final deletedExpense = _expenseBox.get(expenseId);

      // Delete from Firestore
      await _firestore.collection('expenses').doc(expenseId).delete();

      // Delete from local storage
      await _expenseBox.delete(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);

      _notificationService.addActionNotification(
        title: 'Expense Deleted',
        message: deletedExpense != null
            ? '${deletedExpense.amount} removed from ${deletedExpense.category}'
            : 'Expense removed',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Update in Firestore
      await _firestore.collection('expenses').doc(expense.id).update({
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'note': expense.note,
        'userId': _userId,
      });

      // Update in local storage
      await _expenseBox.put(expense.id, expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index >= 0) {
        _expenses[index] = expense;
      }

      _notificationService.addActionNotification(
        title: 'Expense Updated',
        message: '${expense.amount} updated for ${expense.category}',
        relatedId: expense.id,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Get expenses for previous month (for trend calculation)
  Future<Map<String, double>> getExpensesForPreviousMonth(DateTime currentMonth) async {
    final previousMonth = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
      1, // Use 1 for the day to ensure it's the start of the previous month
    );
    // Adapt to the new return type of getExpensesByCategory
    final List<CategoryMonthlySummary> summaries = await getExpensesByCategory(previousMonth);
    final Map<String, double> categoryTotals = {};
    for (final summary in summaries) {
      categoryTotals[summary.categoryName] = summary.totalAmount;
    }
    return categoryTotals;
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

  List<Expense> getExpensesInCategory(String category) {
    return _expenses.where((e) => e.category == category).toList();
  }

  double getTotalExpensesByCategory(String category) {
    return _expenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((e) => e.date.isAfter(start) && e.date.isBefore(end)).toList();
  }

  double getTotalExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

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

  // New methods for "My Spending" card
  Future<double> getTotalExpensesForDateRange(DateTime startDate, DateTime endDate) async {
    final allExpenses = await getAllExpenses(); 
    double total = 0.0;
    for (var expense in allExpenses) {
      // Ensure date comparison is done correctly (ignoring time part)
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      final rangeStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final rangeEndDate = DateTime(endDate.year, endDate.month, endDate.day);

      if (!expenseDate.isBefore(rangeStartDate) && !expenseDate.isAfter(rangeEndDate)) {
        total += expense.amount;
      }
    }
    return total;
  }

  Future<List<double>> getDailyExpensesForWeek(DateTime dateInThatWeek) async {
    final allExpenses = await getAllExpenses(); 
    List<double> dailyTotals = List.filled(7, 0.0); // Monday to Sunday

    // Determine Monday of the week for dateInThatWeek
    // In Dart, weekday is 1 (Monday) to 7 (Sunday).
    int daysToSubtract = dateInThatWeek.weekday - 1; // Monday (1) - 1 = 0. Sunday (7) - 1 = 6.
    DateTime mondayOfWeek = DateTime(dateInThatWeek.year, dateInThatWeek.month, dateInThatWeek.day).subtract(Duration(days: daysToSubtract));
    print('ExpenseService: getDailyExpensesForWeek - dateInThatWeek: $dateInThatWeek, mondayOfWeek: $mondayOfWeek');

    for (var expense in allExpenses) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      // Check if the expense date is within the calculated week (Monday to Sunday)
      if (!expenseDate.isBefore(mondayOfWeek) && 
          expenseDate.isBefore(mondayOfWeek.add(const Duration(days: 7)))) {
        // Calculate which day of the week it is (0 for Monday, 1 for Tuesday, ..., 6 for Sunday)
        int dayIndex = expenseDate.weekday - 1; 
        if (dayIndex >= 0 && dayIndex < 7) { // Safety check
          dailyTotals[dayIndex] += expense.amount;
        }
      }
    }
    print('ExpenseService: getDailyExpensesForWeek - dailyTotals (Mon-Sun): $dailyTotals');
    return dailyTotals;
  }

  // New method for the main expense line chart
  Future<List<FlSpot>> getDailyExpenseSpotsForMonth(DateTime month) async {
    print('ExpenseService: getDailyExpenseSpotsForMonth called for $month. Internal _expenses count: ${_expenses.length}');
    final List<FlSpot> spots = [];
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    // double maxSpending = 0.0; // Not strictly needed if chart auto-scales Y

    for (int i = 1; i <= daysInMonth; i++) {
      final currentDate = DateTime(month.year, month.month, i);
      double dailyTotal = 0.0;

      for (var expense in _expenses) {
        if (expense.date.year == currentDate.year &&
            expense.date.month == currentDate.month &&
            expense.date.day == currentDate.day) {
          dailyTotal += expense.amount;
        }
      }
      // if (dailyTotal > maxSpending) {
      //   maxSpending = dailyTotal;
      // }
      // X-value: (day - 1) so that day 1 is x=0, day 2 is x=1, etc.
      spots.add(FlSpot((i - 1).toDouble(), dailyTotal));
    }
    print('ExpenseService: getDailyExpenseSpotsForMonth for $month returning ${spots.length} spots.');
    return spots;
  }
} 