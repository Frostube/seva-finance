import '../models/expense.dart';
// import 'storage_service.dart'; // Removed
import 'wallet_service.dart';
import 'package:hive/hive.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Removed
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'category_service.dart';
import '../models/wallet.dart';

// Helper class for category summary
class CategoryMonthlySummary {
  final String categoryId;
  final String categoryName;
  final double totalAmount;
  final DateTime latestTransactionDateInMonth;

  CategoryMonthlySummary({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.latestTransactionDateInMonth,
  });
}

class ExpenseService with ChangeNotifier {
  // final StorageService _storageService; // Removed
  // final Box<double> _budgetBox; // Removed
  final Box<Expense> _expenseBox;
  final WalletService _walletService;
  final NotificationService _notificationService;
  final FirebaseFirestore _firestore;
  // final FirebaseStorage _storage; // Removed
  final CategoryService _categoryService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Expense> _expenses = [];
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  ExpenseService(
    // this._storageService, // Removed
    // this._budgetBox, // Removed
    this._expenseBox, 
    this._walletService, 
    this._notificationService, 
    this._firestore, 
    // this._storage, // Removed
    this._categoryService
  ) {
    _initialLoadFuture = _loadExpenses();
  }

  Future<void>? get initializationComplete => _initialLoadFuture;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadExpenses() async {
    if (_isLoading) return;
    _isLoading = true;

    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint('ExpenseService: User not authenticated. Loading expenses from local cache only.');
      _expenses = _expenseBox.values.toList();
      _isLoading = false;
      notifyListeners(); // Notify after local load
      return;
    }

    try {
      debugPrint('ExpenseService: User $currentUserId authenticated. Syncing expenses.');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .get();
      debugPrint('ExpenseService: Fetched ${snapshot.docs.length} expenses from Firestore for user $currentUserId.');
      
      final remoteExpenses = snapshot.docs.map((doc) {
        final data = doc.data();
        // Use Expense.fromJson, ensure 'id' is passed
        return Expense.fromJson({
           ...data,
          'id': doc.id 
        });
      }).toList();

      Map<String, Expense> localExpensesMap = { for (var e in _expenseBox.values) e.id : e };
      Set<String> remoteExpenseIds = {};

      for (final remoteExpense in remoteExpenses) {
        remoteExpenseIds.add(remoteExpense.id);
        await _expenseBox.put(remoteExpense.id, remoteExpense);
        localExpensesMap[remoteExpense.id] = remoteExpense;
      }

      List<String> expensesToDeleteLocally = [];
      for (final localExpenseId in localExpensesMap.keys) {
        if (!remoteExpenseIds.contains(localExpenseId)) {
          expensesToDeleteLocally.add(localExpenseId);
        }
      }
      for (final expenseIdToDelete in expensesToDeleteLocally) {
        await _expenseBox.delete(expenseIdToDelete);
        localExpensesMap.remove(expenseIdToDelete);
        debugPrint('ExpenseService: Deleted expense $expenseIdToDelete from local cache.');
      }
      
      _expenses = localExpensesMap.values.toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date)); // Keep expenses sorted by date
      debugPrint('ExpenseService: Synced ${_expenses.length} expenses.');

    } catch (e) {
      debugPrint('Error syncing expenses with Firestore: $e. Using local cache as fallback.');
      _expenses = _expenseBox.values.toList();
      _expenses.sort((a, b) => b.date.compareTo(a.date)); // Sort fallback too
    }

    _isLoading = false;
    notifyListeners(); // Notify after all loading/syncing is done
  }

  Future<List<Expense>> getAllExpenses() async {
    await initializationComplete;
    return List.from(_expenses);
  }

  Future<List<Expense>> getExpensesForMonth(DateTime month) async {
    await initializationComplete;
    print('ExpenseService: getExpensesForMonth called for month: $month. Internal _expenses count: ${_expenses.length}');
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final filteredExpenses = _expenses.where((expense) {
      return expense.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
             expense.date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
    }).toList();
    print('ExpenseService: getExpensesForMonth for $month returning ${filteredExpenses.length} items.');
    return filteredExpenses;
  }

  Future<double> getTotalForMonth(DateTime month) async {
    final expensesForMonth = await getExpensesForMonth(month);
    return expensesForMonth.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<List<CategoryMonthlySummary>> getExpensesByCategory(DateTime month) async {
    await initializationComplete;
    print('ExpenseService: getExpensesByCategory called for $month');
    final expensesForMonth = await getExpensesForMonth(month);

    if (expensesForMonth.isEmpty) {
      print('ExpenseService: No expenses found for $month. Returning empty list.');
      return [];
    }

    final Map<String, Map<String, dynamic>> categoryData = {};
    
    for (final expense in expensesForMonth) {
      if (!categoryData.containsKey(expense.categoryId)) {
        categoryData[expense.categoryId] = {
          'total': 0.0,
          'latestDate': DateTime(1900),
        };
      }
      categoryData[expense.categoryId]!['total'] = 
          (categoryData[expense.categoryId]!['total'] as double) + expense.amount;
      
      if (expense.date.isAfter(categoryData[expense.categoryId]!['latestDate'] as DateTime)) {
        categoryData[expense.categoryId]!['latestDate'] = expense.date;
      }
    }
    
    final List<CategoryMonthlySummary> summaries = categoryData.entries.map((entry) {
      return CategoryMonthlySummary(
        categoryId: entry.key,
        categoryName: _categoryService.getCategoryNameById(entry.key, defaultName: entry.key),
        totalAmount: entry.value['total'] as double,
        latestTransactionDateInMonth: entry.value['latestDate'] as DateTime,
      );
    }).toList();

    summaries.sort((a, b) {
      int dateCompare = b.latestTransactionDateInMonth.compareTo(a.latestTransactionDateInMonth);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return b.totalAmount.compareTo(a.totalAmount);
    });
    
    print('ExpenseService: getExpensesByCategory for $month returning ${summaries.length} summaries, sorted.');
    return summaries;
  }

  Future<Map<String, dynamic>> getMonthlyExpenseSummaryForLastSixMonths() async {
    await initializationComplete;
    print('ExpenseService: getMonthlyExpenseSummaryForLastSixMonths START');
    final List<FlSpot> spots = [];
    final List<String> monthLabels = [];
    double maxMonthlySpending = 0;

    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final totalForMonth = await getTotalForMonth(targetMonth);
      
      final spotX = 5 - i.toDouble();
      spots.add(FlSpot(spotX, totalForMonth));
      monthLabels.add(DateFormat('MMM').format(targetMonth));

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

  Future<void> addExpense(Expense expense) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
      _isLoading = true;
      notifyListeners();
    try {
      // Use expense.id if provided (e.g., for client-generated IDs), or let Firestore auto-generate
      // For this refactor, assuming expense.id is the one to use.
      final DocumentReference docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expense.id); // Use provided expense.id
      
      Map<String, dynamic> expenseData = expense.toJson();
      expenseData.remove('userId'); // Remove userId as it's in the path

      await docRef.set(expenseData);
      debugPrint('ExpenseService: Expense ${expense.id} added to Firestore for user $currentUserId');

      // Assuming the passed expense object is the one to be stored locally.
      // If Firestore auto-generates ID (using .add()), you would update expense.id here.
      _expenses.add(expense); 
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      await _expenseBox.put(expense.id, expense);
      
      final primaryWallet = _walletService.getPrimaryWallet();
      if (primaryWallet != null) {
        await _walletService.updateWalletBalance(
          primaryWallet.id, 
          primaryWallet.balance - expense.amount
        );
      }
      _notificationService.addActionNotification(
        title: 'Expense Added',
        message: '${_categoryService.getCategoryNameById(expense.categoryId, defaultName: expense.categoryId)} expense of \$${expense.amount} added.',
        relatedId: expense.id,
      );
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
      _isLoading = true;
      notifyListeners();
    try {
      final expenseIndex = _expenses.indexWhere((e) => e.id == expenseId);
      if (expenseIndex == -1) {
        debugPrint('ExpenseService: Expense $expenseId not found in local list for deletion.');
        return; // Or throw error
      }
      final expenseToDelete = _expenses[expenseIndex];

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
      debugPrint('ExpenseService: Expense $expenseId deleted from Firestore for user $currentUserId');

      _expenses.removeAt(expenseIndex);
      // No need to re-sort if already sorted and removing an item
      await _expenseBox.delete(expenseId);
      
      final primaryWallet = _walletService.getPrimaryWallet();
      if (primaryWallet != null) {
        await _walletService.updateWalletBalance(
          primaryWallet.id, 
          primaryWallet.balance + expenseToDelete.amount 
        );
      }
      _notificationService.addActionNotification(
        title: 'Expense Deleted',
        message: 'Expense of \$${expenseToDelete.amount} deleted.',
        relatedId: expenseId,
      );
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExpense(Expense expense) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
      _isLoading = true;
      notifyListeners();
    try {
      Map<String, dynamic> expenseData = expense.toJson();
      expenseData.remove('userId');

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('expenses')
          .doc(expense.id)
          .update(expenseData);
      debugPrint('ExpenseService: Expense ${expense.id} updated in Firestore for user $currentUserId');

      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _expenses.sort((a, b) => b.date.compareTo(a.date)); // Re-sort if date might change
        await _expenseBox.put(expense.id, expense);
      }
      _notificationService.addActionNotification(
        title: 'Expense Updated',
        message: '${_categoryService.getCategoryNameById(expense.categoryId, defaultName: expense.categoryId)} expense updated to \$${expense.amount}.',
        relatedId: expense.id,
      );
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, double>> getExpensesForPreviousMonth(DateTime currentMonth) async {
    await initializationComplete;
    final previousMonth = DateTime(
      currentMonth.year,
      currentMonth.month - 1,
      1, 
    );
    final List<CategoryMonthlySummary> summaries = await getExpensesByCategory(previousMonth);
    final Map<String, double> categoryTotals = {};
    for (final summary in summaries) {
      categoryTotals[summary.categoryName] = summary.totalAmount;
    }
    return categoryTotals;
  }

  Future<double> calculateTrend() async {
    await initializationComplete;
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
    await initializationComplete;
    return List.from(_expenses);
  }

  Future<double> getTotalExpenses() async {
    final expensesList = await getExpenses();
    return expensesList.fold<double>(0.0, (sum, expense) => sum + expense.amount);
  }

  Future<double> getRemainingBudget() async {
    final budget = await getBudget();
    final totalExpenses = await getTotalExpenses();
    return budget - totalExpenses;
  }

  Future<Map<String, List<Expense>>> getExpensesByTimeline() async {
    await initializationComplete;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    final groupedExpenses = {
      'Today': <Expense>[],
      'This Week': <Expense>[],
      'Earlier': <Expense>[],
    };

    final expensesList = await getExpenses();
    expensesList.sort((a, b) => b.date.compareTo(a.date));

    for (var expense in expensesList) {
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

  List<Expense> getExpensesInCategory(String categoryId) {
    return _expenses.where((e) => e.categoryId == categoryId).toList();
  }

  double getTotalExpensesByCategory(String categoryId) {
    return _expenses
        .where((e) => e.categoryId == categoryId)
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
    final walletBudget = _walletService.getWalletBudget(walletId);
    
    if (walletBudget > 0) {
      final monthlyExpenses = await getExpensesForMonth(DateTime.now());
      final totalSpent = monthlyExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
      
      if (totalSpent + amount > walletBudget) {
        _notificationService.addAlertNotification(
          alertId: walletId,
          title: 'Budget Alert',
          message: 'This expense will exceed your monthly budget for the selected wallet.',
        );
      }
    }
  }

  Future<double> getTotalExpensesForDateRange(DateTime startDate, DateTime endDate) async {
    await initializationComplete;
    double total = 0.0;
    for (var expense in _expenses) {
      if (!expense.date.isBefore(startDate) && expense.date.isBefore(endDate.add(const Duration(days: 1)))) {
        total += expense.amount;
      }
    }
    return total;
  }

  Future<List<double>> getDailyExpensesForWeek(DateTime dateInThatWeek) async {
    await initializationComplete;
    List<double> dailyTotals = List.filled(7, 0.0);
    int daysToSubtract = dateInThatWeek.weekday - 1;
    DateTime mondayOfWeek = DateTime(dateInThatWeek.year, dateInThatWeek.month, dateInThatWeek.day).subtract(Duration(days: daysToSubtract));
    print('ExpenseService: getDailyExpensesForWeek - dateInThatWeek: $dateInThatWeek, mondayOfWeek: $mondayOfWeek');

    for (var expense in _expenses) {
      final expenseDate = DateTime(expense.date.year, expense.date.month, expense.date.day);
      if (!expenseDate.isBefore(mondayOfWeek) && 
          expenseDate.isBefore(mondayOfWeek.add(const Duration(days: 7)))) {
        int dayIndex = expenseDate.weekday - 1; 
        if (dayIndex >= 0 && dayIndex < 7) { 
          dailyTotals[dayIndex] += expense.amount;
        }
      }
    }
    print('ExpenseService: getDailyExpensesForWeek - dailyTotals (Mon-Sun): $dailyTotals');
    return dailyTotals;
  }

  Future<List<FlSpot>> getDailyExpenseSpotsForMonth(DateTime month) async {
    await initializationComplete;
    print('ExpenseService: getDailyExpenseSpotsForMonth called for $month. Internal _expenses count: ${_expenses.length}');
    final List<FlSpot> spots = [];
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

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
      spots.add(FlSpot((i - 1).toDouble(), dailyTotal));
    }
    print('ExpenseService: getDailyExpenseSpotsForMonth for $month returning ${spots.length} spots.');
    return spots;
  }

  Future<Expense> recordExpenseAndUpdateWallet(
    double amount,
    String categoryId,
    DateTime date,
    String? note,
    String walletId,
  ) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final newExpenseId = _firestore.collection('users').doc(currentUserId).collection('expenses').doc().id;
    final newExpense = Expense(
      id: newExpenseId,
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: note,
    );
    await addExpense(newExpense);
    return newExpense;
  }

  Future<void> updateExpenseAndUpdateWallet(
    Expense originalExpense,
    double newAmount,
    String newCategoryId,
    DateTime newDate,
    String? newNote,
    String walletId,
  ) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final amountDifference = newAmount - originalExpense.amount;

    final updatedExpense = Expense(
      id: originalExpense.id,
      amount: newAmount,
      categoryId: newCategoryId,
      date: newDate,
      note: newNote,
    );
    await updateExpense(updatedExpense);

    if (amountDifference != 0) {
      Wallet? walletToUpdate;
      if (walletId.isNotEmpty) {
        for (final wallet in _walletService.wallets) {
          if (wallet.id == walletId) {
            walletToUpdate = wallet;
            break;
          }
        }
      }
      walletToUpdate ??= _walletService.getPrimaryWallet();

      if (walletToUpdate != null) {
        await _walletService.updateWalletBalance(
          walletToUpdate.id, 
          walletToUpdate.balance - amountDifference
        );
      }
    }
  }

  Future<Map<String, double>> getExpensesByCategoryForInsights(DateTime month) async {
    await initializationComplete;
    final expensesForMonthList = await getExpensesForMonth(month);
    final Map<String, double> categoryTotals = {};
    for (final expense in expensesForMonthList) {
      final categoryName = _categoryService.getCategoryNameById(expense.categoryId, defaultName: expense.categoryId);
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0.0) + expense.amount;
    }
    return categoryTotals;
  }
} 