import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../models/analytics.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/wallet_service.dart';

class AnalyticsService with ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ExpenseService _expenseService;
  final WalletService _walletService;
  final Box<Analytics> _analyticsBox;

  Analytics? _currentAnalytics;
  bool _isLoading = false;
  Future<void>? _initialLoadFuture;

  AnalyticsService(
    this._firestore,
    this._auth,
    this._expenseService,
    this._walletService,
    this._analyticsBox,
  ) {
    _initialLoadFuture = _loadAnalytics();
  }

  Analytics? get currentAnalytics => _currentAnalytics;
  bool get isLoading => _isLoading;
  Future<void>? get initializationComplete => _initialLoadFuture;
  String? get _userId => _auth.currentUser?.uid;

  Future<void> _loadAnalytics() async {
    if (_isLoading) return;
    _isLoading = true;

    final String? currentUserId = _userId;
    if (currentUserId == null) {
      debugPrint(
          'AnalyticsService: User not authenticated. Loading from local cache only.');
      _currentAnalytics = _analyticsBox.get(currentUserId);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint(
          'AnalyticsService: User $currentUserId authenticated. Syncing analytics.');

      // Try to load from Firestore first
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('analytics')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _currentAnalytics = Analytics.fromJson(data);
        await _analyticsBox.put('current', _currentAnalytics!);
        debugPrint('AnalyticsService: Analytics loaded from Firestore.');
      } else {
        // Generate analytics if none exist
        await _generateAnalytics();
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e. Using local cache as fallback.');
      _currentAnalytics = _analyticsBox.get('current');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _generateAnalytics() async {
    final String? currentUserId = _userId;
    if (currentUserId == null) return;

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);

      // Wait for expense service to be ready
      await _expenseService.initializationComplete;

      // Get all expenses
      final allExpenses = await _expenseService.getAllExpenses();

      // Calculate MTD totals
      final mtdExpenses = allExpenses.where((expense) =>
          expense.date
              .isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
          expense.date.isBefore(now.add(const Duration(days: 1))));

      final mtdTotal =
          mtdExpenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);

      // Calculate MTD by category
      final Map<String, double> mtdByCategory = {};
      for (final expense in mtdExpenses) {
        mtdByCategory[expense.categoryId] =
            (mtdByCategory[expense.categoryId] ?? 0) + expense.amount;
      }

      // Calculate last period by category
      final lastPeriodExpenses = allExpenses.where((expense) =>
          expense.date
              .isAfter(startOfLastMonth.subtract(const Duration(seconds: 1))) &&
          expense.date
              .isBefore(endOfLastMonth.add(const Duration(seconds: 1))));

      final Map<String, double> lastPeriodByCategory = {};
      for (final expense in lastPeriodExpenses) {
        lastPeriodByCategory[expense.categoryId] =
            (lastPeriodByCategory[expense.categoryId] ?? 0) + expense.amount;
      }

      // Calculate rolling averages
      final last7DaysExpenses = allExpenses.where((expense) =>
          expense.date.isAfter(now.subtract(const Duration(days: 7))));
      final avg7d = last7DaysExpenses.fold<double>(
              0.0, (sum, expense) => sum + expense.amount) /
          7;

      final last30DaysExpenses = allExpenses.where((expense) =>
          expense.date.isAfter(now.subtract(const Duration(days: 30))));
      final avg30d = last30DaysExpenses.fold<double>(
              0.0, (sum, expense) => sum + expense.amount) /
          30;

      // Get current balance
      await _walletService.initializationComplete;
      final primaryWallet = _walletService.getPrimaryWallet();
      final currentBalance = primaryWallet?.balance ?? 0.0;

      // Calculate days in month and days passed
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysPassed = now.day - 1;

      _currentAnalytics = Analytics(
        userId: currentUserId,
        mtdTotal: mtdTotal,
        mtdByCategory: mtdByCategory,
        avg7d: avg7d,
        avg30d: avg30d,
        lastPeriodByCategory: lastPeriodByCategory,
        lastUpdated: now,
        currentBalance: currentBalance,
        daysInMonth: daysInMonth,
        daysPassed: daysPassed,
      );

      // Save to both local and Firestore
      await _analyticsBox.put('current', _currentAnalytics!);
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('analytics')
          .doc('current')
          .set(_currentAnalytics!.toJson());

      debugPrint('AnalyticsService: Analytics generated and saved.');
    } catch (e) {
      debugPrint('Error generating analytics: $e');
    }
  }

  Future<void> refreshAnalytics({bool force = false}) async {
    final String? currentUserId = _userId;
    if (currentUserId == null) return;

    // Check if we need to refresh (force or data is older than 1 hour)
    if (!force && _currentAnalytics != null) {
      final lastUpdated = _currentAnalytics!.lastUpdated;
      final hoursSinceUpdate = DateTime.now().difference(lastUpdated).inHours;
      if (hoursSinceUpdate < 1) {
        debugPrint('AnalyticsService: Analytics are fresh, skipping refresh.');
        return;
      }
    }

    await _generateAnalytics();
    notifyListeners();
  }

  // Forecast methods
  double getForecastedBalance() {
    if (_currentAnalytics == null) return 0.0;

    final analytics = _currentAnalytics!;
    final daysLeft = analytics.daysInMonth - analytics.daysPassed;

    if (daysLeft <= 0) return analytics.currentBalance;

    final forecastedSpending = analytics.avg30d * daysLeft;
    return analytics.currentBalance - forecastedSpending;
  }

  Map<String, double> getForecastedCategorySpending() {
    if (_currentAnalytics == null) return {};

    final analytics = _currentAnalytics!;
    final daysLeft = analytics.daysInMonth - analytics.daysPassed;

    if (daysLeft <= 0) return analytics.mtdByCategory;

    final Map<String, double> forecasted = {};
    final totalMtd = analytics.mtdTotal;

    for (final entry in analytics.mtdByCategory.entries) {
      final categoryId = entry.key;
      final currentSpending = entry.value;

      // Calculate daily average for this category
      final dailyAvg = analytics.daysPassed > 0
          ? currentSpending / analytics.daysPassed
          : 0.0;

      // Forecast remaining spending
      final forecastedRemaining = dailyAvg * daysLeft;
      forecasted[categoryId] = currentSpending + forecastedRemaining;
    }

    return forecasted;
  }

  double getMonthlySpendingTrend() {
    if (_currentAnalytics == null) return 0.0;

    final analytics = _currentAnalytics!;
    final currentMtd = analytics.mtdTotal;
    final lastPeriodTotal = analytics.lastPeriodByCategory.values
        .fold<double>(0.0, (sum, amount) => sum + amount);

    if (lastPeriodTotal == 0) return 0.0;

    return ((currentMtd - lastPeriodTotal) / lastPeriodTotal) * 100;
  }

  Map<String, double> getCategoryTrends() {
    if (_currentAnalytics == null) return {};

    final analytics = _currentAnalytics!;
    final Map<String, double> trends = {};

    for (final entry in analytics.mtdByCategory.entries) {
      final categoryId = entry.key;
      final currentAmount = entry.value;
      final lastPeriodAmount =
          analytics.lastPeriodByCategory[categoryId] ?? 0.0;

      if (lastPeriodAmount > 0) {
        trends[categoryId] =
            ((currentAmount - lastPeriodAmount) / lastPeriodAmount) * 100;
      } else if (currentAmount > 0) {
        trends[categoryId] = 100.0; // New spending in this category
      }
    }

    return trends;
  }

  bool isSpendingAboveAverage() {
    if (_currentAnalytics == null) return false;

    final analytics = _currentAnalytics!;
    final dailyMtdAverage = analytics.daysPassed > 0
        ? analytics.mtdTotal / analytics.daysPassed
        : 0.0;

    return dailyMtdAverage > analytics.avg30d;
  }

  Future<void> clearLocalData() async {
    await _analyticsBox.clear();
    _currentAnalytics = null;
    notifyListeners();
  }
}
