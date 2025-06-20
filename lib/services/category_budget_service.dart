import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_budget.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/notification_service.dart';

class CategoryBudgetService with ChangeNotifier {
  final Box<CategoryBudget> _categoryBudgetsBox;
  final FirebaseFirestore _firestore;
  final ExpenseService _expenseService;
  final NotificationService _notificationService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CategoryBudget> _categoryBudgets = [];
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  CategoryBudgetService(
    this._categoryBudgetsBox,
    this._firestore,
    this._expenseService,
    this._notificationService,
  ) {
    _initialLoadFuture = _loadCategoryBudgets();
  }

  List<CategoryBudget> get categoryBudgets => _categoryBudgets;
  bool get isLoading => _isLoading;
  Future<void>? get initializationComplete => _initialLoadFuture;

  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadCategoryBudgets() async {
    if (_isLoading) return;
    _isLoading = true;

    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint(
          'CategoryBudgetService: User not authenticated. Loading from local cache only.');
      _categoryBudgets = _categoryBudgetsBox.values.toList();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint(
          'CategoryBudgetService: User $currentUserId authenticated. Syncing category budgets.');
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('categoryBudgets')
          .get();

      debugPrint(
          'CategoryBudgetService: Fetched ${snapshot.docs.length} category budgets from Firestore.');

      final remoteBudgets = snapshot.docs.map((doc) {
        return CategoryBudget.fromJson(doc.data(), doc.id);
      }).toList();

      Map<String, CategoryBudget> localBudgetsMap = {
        for (var b in _categoryBudgetsBox.values) b.id: b
      };
      Set<String> remoteBudgetIds = {};

      for (final remoteBudget in remoteBudgets) {
        remoteBudgetIds.add(remoteBudget.id);
        await _categoryBudgetsBox.put(remoteBudget.id, remoteBudget);
        localBudgetsMap[remoteBudget.id] = remoteBudget;
      }

      List<String> budgetsToDeleteLocally = [];
      for (final localBudgetId in localBudgetsMap.keys) {
        if (!remoteBudgetIds.contains(localBudgetId)) {
          budgetsToDeleteLocally.add(localBudgetId);
        }
      }
      for (final budgetIdToDelete in budgetsToDeleteLocally) {
        await _categoryBudgetsBox.delete(budgetIdToDelete);
        localBudgetsMap.remove(budgetIdToDelete);
        debugPrint(
            'CategoryBudgetService: Deleted budget $budgetIdToDelete from local cache.');
      }

      _categoryBudgets = localBudgetsMap.values.toList();
      debugPrint(
          'CategoryBudgetService: Synced ${_categoryBudgets.length} category budgets.');
    } catch (e) {
      debugPrint(
          'Error syncing category budgets: $e. Using local cache as fallback.');
      _categoryBudgets = _categoryBudgetsBox.values.toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get category budgets for a specific wallet and month
  List<CategoryBudget> getCategoryBudgetsForWalletAndMonth(
      String walletId, DateTime month) {
    final targetMonth = DateTime(month.year, month.month, 1);
    return _categoryBudgets
        .where((budget) =>
            budget.walletId == walletId &&
            budget.month.year == targetMonth.year &&
            budget.month.month == targetMonth.month)
        .toList();
  }

  /// Get a specific category budget
  CategoryBudget? getCategoryBudget(
      String walletId, String categoryId, DateTime month) {
    final targetMonth = DateTime(month.year, month.month, 1);
    return _categoryBudgets.firstWhere(
      (budget) =>
          budget.walletId == walletId &&
          budget.categoryId == categoryId &&
          budget.month.year == targetMonth.year &&
          budget.month.month == targetMonth.month,
      orElse: () => null as CategoryBudget,
    );
  }

  /// Create category budgets from template items
  Future<void> createCategoryBudgetsFromTemplate({
    required String walletId,
    required List<Map<String, dynamic>>
        templateItems, // {categoryId, categoryName, amount}
    required DateTime month,
    String? templateId,
  }) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      final targetMonth = DateTime(month.year, month.month, 1);

      // Delete existing budgets for this wallet and month
      await _deleteCategoryBudgetsForWalletAndMonth(walletId, targetMonth);

      // Create new category budgets
      for (final item in templateItems) {
        final categoryBudget = CategoryBudget(
          id: DateTime.now().millisecondsSinceEpoch.toString() +
              '_${item['categoryId']}',
          walletId: walletId,
          categoryId: item['categoryId'] as String,
          categoryName: item['categoryName'] as String,
          budgetAmount: (item['amount'] as num).toDouble(),
          month: targetMonth,
          templateId: templateId,
        );

        await _addCategoryBudget(categoryBudget);
      }

      debugPrint(
          'CategoryBudgetService: Created ${templateItems.length} category budgets from template');
    } catch (e) {
      debugPrint('Error creating category budgets from template: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a single category budget
  Future<void> _addCategoryBudget(CategoryBudget budget) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');

    try {
      final docRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('categoryBudgets')
          .doc(budget.id);

      await docRef.set(budget.toJson());
      _categoryBudgets.add(budget);
      await _categoryBudgetsBox.put(budget.id, budget);
    } catch (e) {
      debugPrint('Error adding category budget: $e');
      rethrow;
    }
  }

  /// Delete category budgets for a specific wallet and month
  Future<void> _deleteCategoryBudgetsForWalletAndMonth(
      String walletId, DateTime month) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');

    final budgetsToDelete =
        getCategoryBudgetsForWalletAndMonth(walletId, month);

    for (final budget in budgetsToDelete) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('categoryBudgets')
            .doc(budget.id)
            .delete();

        _categoryBudgets.removeWhere((b) => b.id == budget.id);
        await _categoryBudgetsBox.delete(budget.id);
      } catch (e) {
        debugPrint('Error deleting category budget ${budget.id}: $e');
      }
    }
  }

  /// Get current spending for a category in a specific month
  Future<double> getCategorySpending(String categoryId, DateTime month) async {
    try {
      if (_expenseService.initializationComplete != null) {
        await _expenseService.initializationComplete;
      }
      final expenses = await _expenseService.getExpensesForMonth(month);
      return expenses
          .where((expense) => expense.categoryId == categoryId)
          .fold<double>(0.0, (sum, expense) => sum + expense.amount);
    } catch (e) {
      debugPrint('Error getting category spending: $e');
      return 0.0;
    }
  }

  /// Get budget status with current spending for a category
  Future<Map<String, dynamic>> getCategoryBudgetStatus(
      String walletId, String categoryId, DateTime month) async {
    final budget = getCategoryBudget(walletId, categoryId, month);
    if (budget == null) {
      return {
        'hasBudget': false,
        'budgetAmount': 0.0,
        'currentSpending': 0.0,
        'remainingBudget': 0.0,
        'progress': 0.0,
        'status': BudgetStatus.underSpent,
        'shouldAlert': false,
      };
    }

    final currentSpending = await getCategorySpending(categoryId, month);

    return {
      'hasBudget': true,
      'budgetAmount': budget.budgetAmount,
      'currentSpending': currentSpending,
      'remainingBudget': budget.getRemainingBudget(currentSpending),
      'progress': budget.getSpendingProgress(currentSpending),
      'status': budget.getBudgetStatus(currentSpending),
      'shouldAlert': budget.shouldTriggerAlert(currentSpending),
      'remainingText': budget.getRemainingBudgetText(currentSpending),
    };
  }

  /// Check all category budgets for alerts
  Future<void> checkCategoryBudgetAlerts(
      String walletId, DateTime month) async {
    final budgets = getCategoryBudgetsForWalletAndMonth(walletId, month);

    for (final budget in budgets) {
      final currentSpending =
          await getCategorySpending(budget.categoryId, month);

      if (budget.shouldTriggerAlert(currentSpending)) {
        final progress =
            (budget.getSpendingProgress(currentSpending) * 100).toInt();

        _notificationService.addAlertNotification(
          alertId: 'category_${budget.id}',
          title: '${budget.categoryName} Budget Alert',
          message:
              'You\'ve spent ${progress}% of your ${budget.categoryName} budget (\$${currentSpending.toStringAsFixed(0)} of \$${budget.budgetAmount.toStringAsFixed(0)})',
        );
      }
    }
  }

  /// Get overview of all category budgets for a wallet and month
  Future<Map<String, dynamic>> getCategoryBudgetOverview(
      String walletId, DateTime month) async {
    final budgets = getCategoryBudgetsForWalletAndMonth(walletId, month);

    if (budgets.isEmpty) {
      return {
        'totalBudget': 0.0,
        'totalSpent': 0.0,
        'categoriesOverBudget': 0,
        'categoriesOnTrack': 0,
        'budgetDetails': <Map<String, dynamic>>[],
      };
    }

    double totalBudget = 0.0;
    double totalSpent = 0.0;
    int categoriesOverBudget = 0;
    int categoriesOnTrack = 0;
    List<Map<String, dynamic>> budgetDetails = [];

    for (final budget in budgets) {
      final currentSpending =
          await getCategorySpending(budget.categoryId, month);
      final status = budget.getBudgetStatus(currentSpending);

      totalBudget += budget.budgetAmount;
      totalSpent += currentSpending;

      if (status == BudgetStatus.overBudget) categoriesOverBudget++;
      if (status == BudgetStatus.onTrack) categoriesOnTrack++;

      budgetDetails.add({
        'categoryId': budget.categoryId,
        'categoryName': budget.categoryName,
        'budgetAmount': budget.budgetAmount,
        'currentSpending': currentSpending,
        'progress': budget.getSpendingProgress(currentSpending),
        'status': status,
        'remainingText': budget.getRemainingBudgetText(currentSpending),
      });
    }

    // Sort by spending progress (highest first)
    budgetDetails.sort(
        (a, b) => (b['progress'] as double).compareTo(a['progress'] as double));

    return {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'categoriesOverBudget': categoriesOverBudget,
      'categoriesOnTrack': categoriesOnTrack,
      'budgetDetails': budgetDetails,
    };
  }

  /// Update category budget amount
  Future<void> updateCategoryBudget(String budgetId, double newAmount) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('categoryBudgets')
          .doc(budgetId)
          .update({'budgetAmount': newAmount});

      final index = _categoryBudgets.indexWhere((b) => b.id == budgetId);
      if (index != -1) {
        final oldBudget = _categoryBudgets[index];
        final updatedBudget = CategoryBudget(
          id: oldBudget.id,
          walletId: oldBudget.walletId,
          categoryId: oldBudget.categoryId,
          categoryName: oldBudget.categoryName,
          budgetAmount: newAmount,
          month: oldBudget.month,
          createdAt: oldBudget.createdAt,
          templateId: oldBudget.templateId,
          alertsEnabled: oldBudget.alertsEnabled,
          alertThreshold: oldBudget.alertThreshold,
        );

        _categoryBudgets[index] = updatedBudget;
        await _categoryBudgetsBox.put(budgetId, updatedBudget);
      }
    } catch (e) {
      debugPrint('Error updating category budget: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a category budget
  Future<void> deleteCategoryBudget(String budgetId) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('categoryBudgets')
          .doc(budgetId)
          .delete();

      _categoryBudgets.removeWhere((b) => b.id == budgetId);
      await _categoryBudgetsBox.delete(budgetId);
    } catch (e) {
      debugPrint('Error deleting category budget: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all category budgets for a specific wallet and month
  Future<void> clearCategoryBudgetsForMonth(
      String walletId, DateTime month) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) throw Exception('User not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      // Get all budgets for this wallet and month
      final budgetsToDelete =
          getCategoryBudgetsForWalletAndMonth(walletId, month);

      // Delete from Firestore
      final batch = _firestore.batch();
      for (final budget in budgetsToDelete) {
        final docRef = _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('categoryBudgets')
            .doc(budget.id);
        batch.delete(docRef);
      }
      await batch.commit();

      // Remove from local storage
      for (final budget in budgetsToDelete) {
        _categoryBudgets.removeWhere((b) => b.id == budget.id);
        await _categoryBudgetsBox.delete(budget.id);
      }

      debugPrint(
          'CategoryBudgetService: Cleared ${budgetsToDelete.length} category budgets for wallet $walletId and month ${month.toIso8601String()}');
    } catch (e) {
      debugPrint('Error clearing category budgets: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
