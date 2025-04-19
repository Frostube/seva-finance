import '../models/expense.dart';
import 'storage_service.dart';
import 'wallet_service.dart';
import 'package:hive/hive.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  ExpenseService(this._storageService, this._budgetBox, this._expenseBox, this._walletService, this._notificationService, this._firestore, this._storage) {
    _loadExpenses();
  }

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
      _expenses.add(updatedExpense);

      _notificationService.addActionNotification(
        title: 'New Expense Added',
        message: '${expense.amount} spent on ${expense.category}',
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

  Future<void> deleteExpense(String expenseId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete from Firestore
      await _firestore.collection('expenses').doc(expenseId).delete();

      // Delete from local storage
      await _expenseBox.delete(expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);

      _notificationService.addActionNotification(
        title: 'Expense Deleted',
        message: '${_expenseBox.get(expenseId)?.amount} removed from ${_expenseBox.get(expenseId)?.category}',
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
} 